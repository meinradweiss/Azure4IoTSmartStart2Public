CREATE PROCEDURE [Partition].[RemoveDataPartitionsFromTable] 
                               @SchemaName              SYSNAME  
                              ,@TableName               SYSNAME  
							  ,@TS_Day_LowWaterMark     INT    -- Including this day >=
							  ,@TS_Day_HighWaterMark    INT     -- Including this day <=
							  ,@PreserveSwitchOutTable  TINYINT = 0
AS

BEGIN
  SET XACT_ABORT ON
  SET NOCOUNT ON
  SET DATEFORMAT YMD

  DECLARE @ArchiveSchemaName SYSNAME = 'Archive' 

  DECLARE @TaskId BIGINT
  DECLARE @TaskParameterValues NVARCHAR(max)
  SET @TaskParameterValues = '@SchemaName = ' + convert(varchar, @SchemaName) + ',@TableName = ' + convert(varchar, @TableName) + ',@TS_Day_LowWaterMark = ' + convert(varchar, @TS_Day_LowWaterMark) +',@TS_Day_HighWaterMark = ' + convert(varchar, @TS_Day_HighWaterMark)
  EXEC [Logging].[StartTask]  'RemoveDataPartitionsFromTable', @TaskParameterValues, @TaskId =   @TaskId output

  DECLARE @SQL                  NVARCHAR(MAX)
         ,@StepParameterValues  NVARCHAR(max)
		 ,@Ts_Day               INT
		 ,@UpperBoundary_Ts_Day INT



	 
  DECLARE @PartitionsToProcess CURSOR
  
  SET @PartitionsToProcess = CURSOR FOR
  with PartitionInfo
  as
  (
  SELECT 
      t.name AS [Table], 
      i.name AS [Index], 
      p.partition_number,
  	  p.rows,
      f.name,
	  f.function_id,
      r.boundary_id, 
      CONVERT(INT, r.value) AS [BoundaryValue]   
  FROM sys.tables AS t  
  JOIN sys.indexes AS i  
      ON t.object_id = i.object_id  
  JOIN sys.partitions AS p
      ON i.object_id = p.object_id AND i.index_id = p.index_id   
  JOIN  sys.partition_schemes AS s   
      ON i.data_space_id = s.data_space_id  
  JOIN sys.partition_functions AS f   
      ON s.function_id = f.function_id  
  LEFT JOIN sys.partition_range_values AS r   
      ON f.function_id = r.function_id and r.boundary_id = p.partition_number  
  WHERE t.name      = @TableName
    AND t.schema_id = schema_id(@SchemaName)
  )
  ,BoundaryInfo
  AS
  (
  SELECT DISTINCT  BoundaryValue AS Ts_Day, function_id
  FROM  PartitionInfo
  WHERE BoundaryValue  >= @TS_Day_LowWaterMark
    AND BoundaryValue  <= @TS_Day_HighWaterMark
  )
  SELECT Ts_Day
       , IsNull((SELECT MIN(CONVERT(INT, value))                    -- In a month partition there can be more than on Ts_Day value
	             FROM sys.partition_range_values 
				 WHERE function_id = BoundaryInfo.function_id 
				   AND CONVERT(INT, VALUE) > Ts_Day)
	            , @TS_Day_HighWaterMark) as UpperBoundary_Ts_Day
  FROM BoundaryInfo
  ORDER BY Ts_Day ASC

  OPEN @PartitionsToProcess  
  
  FETCH NEXT FROM @PartitionsToProcess   
  INTO @Ts_Day, @UpperBoundary_Ts_Day
  
  WHILE @@FETCH_STATUS = 0  
  BEGIN 

    DECLARE @SwitchOutAndDropStepId   BIGINT
           ,@CheckConstraintSQL       NVARCHAR(MAX)
           ,@EmptyTableName           SYSNAME       
           ,@ArchiveTableName         SYSNAME       
		   ,@StartTime                DATETIME2(3)
		   ,@Partition_number         INT
           ,@NumberOfRowsInPartition  BIGINT
           ,@RowsInPartitionText      NVARCHAR(MAX)


	SET @StartTime = GETUTCDATE()
	SET @StepParameterValues = 'Ts_Day = ' + CONVERT(VARCHAR, @Ts_Day)
    
	EXEC [Logging].[StartStep] @TaskId, 'Switch data out and delete partition data', @StepParameterValues, @StepId =   @SwitchOutAndDropStepId output


    -- Count the number of rows in partition
    SET @SQL = CONCAT('SELECT @NumberOfRowsInPartition = COUNT(*) FROM ', QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName), ' WHERE Ts_DAY >= ', CONVERT(NVARCHAR(MAX), @Ts_Day), ' AND Ts_Day < ', CONVERT(NVARCHAR(MAX), @UpperBoundary_Ts_Day))
    
    EXECUTE sp_executesql @SQL, N'@NumberOfRowsInPartition INT OUTPUT', @NumberOfRowsInPartition=@NumberOfRowsInPartition OUTPUT
  
    IF @NumberOfRowsInPartition = 0
      BEGIN
        EXEC [Logging].[EndStep] @SwitchOutAndDropStepId, 'End', 'No rows in partition -> switch skipped'
      END
    ELSE
      BEGIN

  	    BEGIN TRANSACTION
        
	      -- Switch data out and drop the corresponding table
          
          -- Get Partition Number and required check constraint sql
	      EXEC  [Partition].[GetPartition_Number] @SchemaName, @TableName, @Ts_Day, @Partition_Number OUTPUT
          SELECT @CheckConstraintSQL = [Partition].[GetPartitionRangeCheckConstraint](@SchemaName, @TableName, @Partition_Number)
          
          
          -- Create the table for the switched out data
          SET @ArchiveTableName = CONCAT('SwitchedOut_', @TableName, '_', @Ts_Day, '_', CONVERT(VARCHAR, GETUTCDATE(),126))

          -- Create Switch Table
	      EXEC  [Partition].[CloneTable] @SourceSchemaName        = @SchemaName
                                        ,@SourceTableName         = @TableName
                                        ,@TargetSchemaName        = @ArchiveSchemaName
                                        ,@TargetTableName         = @ArchiveTableName
						    			,@ForceStorageLocation    = '[PRIMARY]'
                                        ,@ConstraintNamePrefix    = 'CK_Ts_Day'
                                        ,@ConstraintDefinition    = @CheckConstraintSQL
          
          
          -- Switch out partition that contains the data
          SET @SQL = CONCAT('ALTER TABLE [', @SchemaName, '].[', @TableName, '] SWITCH PARTITION ', @partition_number, ' TO [', @ArchiveSchemaName , '].', QUOTENAME(@ArchiveTableName))
          EXEC sp_executesql @SQL
          
          
	      -- Drop transfer table, if data should not be preserved
	      IF @PreserveSwitchOutTable = 0
	      BEGIN
	        SET @SQL = CONCAT('DROP TABLE [', @ArchiveSchemaName, '].', QUOTENAME(@ArchiveTableName));
            EXEC sp_executesql @SQL
          END
        
        
        COMMIT
        
        SET @RowsInPartitionText = 'RowsInPartition = ' + Convert(varchar, @NumberOfRowsInPartition);
        EXEC [Logging].[EndStep] @SwitchOutAndDropStepId, 'End', @RowsInPartitionText

      END -- Check @NumberOfRowsInPartition


	FETCH NEXT FROM @PartitionsToProcess   
    INTO @Ts_Day, @UpperBoundary_Ts_Day


  END -- While loop

  
  CLOSE @PartitionsToProcess
  DEALLOCATE @PartitionsToProcess

  EXEC [Logging].[EndTask]  @TaskId, 'End', NULL

END

