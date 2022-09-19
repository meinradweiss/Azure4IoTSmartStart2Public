CREATE PROCEDURE [Core].[MoveDataFromTransferToStore](@TaskId BIGINT
												   , @DropHistoryTable BIT = 1)
AS
BEGIN


  SET NOCOUNT ON
  SET XACT_ABORT OFF

  DECLARE @StartTrancount INT
  SET @StartTrancount = @@TRANCOUNT


  DECLARE  @StepParameterValues NVARCHAR(max)
          ,@ThisStepId          INT
		  ,@Ts_Day              INT
          ,@StartTime           DATETIME2(3)


  SET @StartTime = GETUTCDATE()

  DECLARE @PrintMessage NVARCHAR(MAX)

  -- If a partition merge happend, then more than on Ts_Day may be in the partition. 
  SELECT @Ts_Day = MIN(Ts_Day) 
  FROM [Core].[MeasurementTransfer];

  SET @StepParameterValues = '@Ts_Day: ' + CONVERT(NVARCHAR, @Ts_Day) + ' @DropHistoryTable: ' + CONVERT(NVARCHAR, @DropHistoryTable)
  EXEC [Logging].[StartStep] @TaskId, 'MoveDateFromTransferToStore', @StepParameterValues, @StepId=@ThisStepId output

  DECLARE @Sql                 NVARCHAR(MAX)
        
         ,@RowsAffected        INT
         ,@Partition_Number    INT
         ,@CheckConstraintSQL  NVARCHAR(max)    
		 ,@HistoryTableName    sysname
		 ,@RowsAffectedText    NVARCHAR(max)  



  BEGIN TRY
    SET @PrintMessage = CONCAT('MoveDataFromTransferToStore Ts_Day: ', @Ts_Day)
    EXEC [Helper].[Conditional_print] @PrintMessage

    BEGIN TRANSACTION

      IF @Ts_Day IS NULL
		    RAISERROR('No records in table [Core].[MeasurementTransfer]', 15, 1);
    
	  -- Create switch out table for transfer
	  --EXEC  [Partition].[GetPartition_Number]                                     'Core', 'Measurement', @Ts_Day, @Partition_Number OUTPUT
	  SELECT @Partition_Number   = $PARTITION.dayPartitionFunction(@Ts_Day)
      SELECT @CheckConstraintSQL = [Partition].[GetPartitionRangeCheckConstraint]('Core', 'Measurement', @Partition_Number)
	  SET @HistoryTableName = CONCAT('History_', 'Measurement','_', @Ts_Day, '_', CONVERT(VARCHAR, GETUTCDATE(),126))

      -- Create Switch Table
      EXEC [Helper].[Conditional_print] 'Create Switch Table'

	  EXEC  [Partition].[CloneTable] @SourceSchemaName        = 'Core'
                                    ,@SourceTableName         = 'MeasurementTransfer'
                                    ,@TargetSchemaName        = 'Transfer'
                                    ,@TargetTableName         = @HistoryTableName
									,@ForceStorageLocation    = '[PRIMARY]'
                                    ,@ConstraintNamePrefix    = 'CK_Ts_Day'
                                    ,@ConstraintDefinition    = @CheckConstraintSQL


      EXEC [Helper].[Conditional_print] 'Copy data to [MeasurementStore]'
      -- Copy Data
      INSERT INTO [Core].[MeasurementStore] ([Ts], [Ts_Day], [SignalId], [MeasurementValue], [MeasurementText])
	     SELECT [Ts], [Ts_Day], [SignalId], [MeasurementValue], [MeasurementText]
	     FROM   [Core].[MeasurementTransfer];
         SET @RowsAffected =  @@ROWCOUNT;
	   

      EXEC [Helper].[Conditional_print] 'Switch partition out'
      -- Switch transfer table out to avoid duplicated rows
      SET @Sql = CONCAT('ALTER TABLE [Core].[MeasurementTransfer] SWITCH PARTITION ', @Partition_Number, ' TO [Transfer].', QUOTENAME(@HistoryTableName));
      EXEC sp_executesql @Sql
	  SET @Sql = ''
	   
	  IF @DropHistoryTable = 1
	  BEGIN
        EXEC [Helper].[Conditional_print] 'Drop history table'
        -- Drop history table
        SET @Sql = CONCAT('DROP TABLE [Transfer].', QUOTENAME(@HistoryTableName));
        EXEC sp_executesql @Sql
	  END
	  SET @Sql = ''

      -- Log successful end	   
      SET @RowsAffectedText = 'RowsTransferred = ' + Convert(varchar, @RowsAffected);
	  EXEC [Logging].[EndStep] @ThisStepId, 'End', @RowsAffectedText
	   
	   
  
    COMMIT TRANSACTION;    
    SET @PrintMessage = CONCAT('MoveDataFromTransferToStore Ts_Day: ', @Ts_Day, ' ... done')
    EXEC [Helper].[Conditional_print] @PrintMessage
  END TRY  
  


  /*********************************************************************/
  BEGIN CATCH

	DECLARE @PrintText NVARCHAR(MAX)
    SET @PrintText = CONCAT('Exception catched; Procedure = ', OBJECT_NAME(@@PROCID), '; @StartTrancount=', @StartTrancount, '; @@TRANCOUNT = ', @@TRANCOUNT, ' @Sql= ', @Sql)
    PRINT @PrintText

    IF @StartTrancount = 0
    BEGIN
      IF @@TRANCOUNT > 0  
      BEGIN
        SET @PrintText = @PrintText + '; Action = Rollback transaction'
        PRINT @PrintText
        ROLLBACK TRANSACTION;  
      END
      ELSE -- @@TRANCOUNT > 0  
      BEGIN
        SET @PrintText = @PrintText + '; Action = No open transaction, no action'
        PRINT @PrintText
      END

      DECLARE @ErrorMessage NVARCHAR(MAX)
	  SELECT @ErrorMessage= ERROR_MESSAGE();
	  EXEC [Logging].[EndTask]  @TaskId, 'Error', @ErrorMessage;

    END
    ELSE  -- @StartTrancount = 0
    BEGIN
      SET @PrintText = @PrintText + '; Action = Part of outer transaction. No rollback executed!!!'
      PRINT @PrintText
    END;



	THROW;
  END CATCH
  /*********************************************************************/

END