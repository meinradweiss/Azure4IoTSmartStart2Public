
CREATE PROCEDURE [Core].[RebuildIndexPartitionAndUpdateStatistics] (@TaskId          BIGINT
                                                                   ,@TableSchemaName SYSNAME
												                   ,@TableName       SYSNAME
												                   ,@IndexName       SYSNAME
												                   ,@PartitionNumber INT
												                   )

AS
BEGIN


      DECLARE @SQLString           NVARCHAR(MAX)
 	         ,@StepId              BIGINT
			 ,@StepParameterValues NVARCHAR(max)


      -- Rebuild Index
	  SET @SQLString =  'ALTER INDEX   [' + @IndexName + '] ON [' + @TableSchemaName + '].[' + @TableName + '] '
      SET @SQLString += 'REBUILD Partition = ' + convert(varchar, @PartitionNumber) + ' WITH (ONLINE=ON);'

      SET @StepParameterValues = @SQLString
	  EXEC [Logging].[StartStep] @TaskId, 'RebuildIndex', @StepParameterValues, @StepId =   @StepId output


	  EXEC [Helper].[Conditional_sp_executesql_print] @SQLString

	  EXEC [Logging].[EndStep] @StepId, 'End', NULL

	  -- Check if it is a columnstore index
	  IF EXISTS (SELECT TOP 1 'X'
	             FROM sys.indexes
	             WHERE type_desc IN ('CLUSTERED COLUMNSTORE', 'NONCLUSTERED COLUMNSTORE')
	             AND object_id = OBJECT_ID(CONCAT(@TableSchemaName ,'.',@TableName)))
      BEGIN
	    EXEC [Logging].[StartStep] @TaskId, 'UPDATE STATISTICS', 'Skipped, COLUMNSTORE INDEX', @StepId =   @StepId output
		EXEC [Logging].[EndStep] @StepId, 'End', NULL
	    
	  END
	  ELSE
	  -- Check incremental support
	  IF EXISTS (SELECT TOP 1 'X'
				 FROM sys.stats s
                   INNER JOIN sys.indexes i 
				      ON i.name = s.name
                     AND i.object_id = s.object_id
                  WHERE S.is_incremental = 0
				    AND i.object_id =  OBJECT_ID(CONCAT(@TableSchemaName ,'.',@TableName)))
	  BEGIN
	    EXEC [Logging].[StartStep] @TaskId, 'UPDATE STATISTICS', 'Skipped, incremental not supported, rebuild index with (STATISTICS_INCREMENTAL  = ON)', @StepId =   @StepId output
		EXEC [Logging].[EndStep] @StepId, 'End', NULL
	  END
	  ELSE

	  BEGIN

  	    -- Yes, we can: Update statistics
	    SET @SQLString =  'UPDATE STATISTICS [' + @TableSchemaName + '].[' + @TableName + '] (' + @IndexName + ') '
        SET @SQLString += 'WITH RESAMPLE ON PARTITIONS(' + convert(varchar, @PartitionNumber) + ');'

        SET @StepParameterValues = @SQLString
		
	    EXEC [Logging].[StartStep] @TaskId, 'UPDATE STATISTICS', @StepParameterValues, @StepId =   @StepId output

	    EXEC [Helper].[Conditional_sp_executesql_print] @SQLString
	    
		EXEC [Logging].[EndStep] @StepId, 'End', NULL
	 END

END