




CREATE PROCEDURE [Core].[OptimiseDataStorage] @measureMonthLowWaterMark  DATETIME2 (0) = '1900.01.01'   -- Ts_Day >=
											, @measureMonthHighWaterMark DATETIME2 (0) = '9999.12.31'   -- Ts_Day <=
                                            , @DropHistoryTable BIT = 1
AS

BEGIN



  SET NOCOUNT ON
  SET XACT_ABORT OFF
  SET DATEFORMAT YMD 

  DECLARE @StartTrancount INT
   SET @StartTrancount = @@TRANCOUNT

  DECLARE @PrintMessage NVARCHAR(MAX)

  DECLARE @TaskId BIGINT
  DECLARE @TaskParameterValues NVARCHAR(max)
  SET @TaskParameterValues = '@measureMonthLowWaterMark = '  + convert(varchar, @measureMonthLowWaterMark) 
                         + ', @measureMonthHighWaterMark = ' + convert(varchar, @measureMonthHighWaterMark) 
						 + ', @DropHistoryTable = '          + convert(varchar, @DropHistoryTable) 
  EXEC [Logging].[StartTask]  'OptimiseDataStorage', @TaskParameterValues, @TaskId =   @TaskId output

  DECLARE @SQL                 NVARCHAR(MAX)
         ,@StartTime           DATETIME2(3)
		 ,@RowsAffectedText    NVARCHAR(max)
         ,@RowsAffected        INT
		 ,@HistoryTableName    SYSNAME
		 ,@Partition_Number    INT
         ,@StepParameterValues NVARCHAR(max)
		 ,@Ts_Day              DATETIME2 (0)

  BEGIN TRY

    /*    Check if old data exists. This may happen if process stopped after the first commit part */
    IF (SELECT COUNT(*) FROM [Core].[MeasurementTransfer]) > 0
    BEGIN
      EXEC [Helper].[Conditional_print] 'Old data in [Core].[MeasurementTransfer] pre processing necessary'

      DECLARE @MinTs_DayOfTransfer DATE
	         ,@CleanUpLastOptimiseRunStepId bigint


	  SELECT @MinTs_DayOfTransfer = MIN(Ts_Day) 
  	  FROM [Core].[MeasurementTransfer];

	  SET @StepParameterValues = 'Min Ts_Day found in [Core].[MeasurementTransfer] = ' + CONVERT(VARCHAR, @MinTs_DayOfTransfer)
      EXEC [Logging].[StartStep] @TaskId, 'CDMS, copy old recourds found in MeasurementTransfer', @StepParameterValues, @StepId =   @CleanUpLastOptimiseRunStepId output


	  SET @StartTime = GETUTCDATE()

	  BEGIN TRANSACTION

	    EXEC [Core].[MoveDataFromTransferToStore] @TaskId=@TaskId,  @DropHistoryTable=@DropHistoryTable

	  COMMIT
      EXEC [Helper].[Conditional_print] 'Old data in [Core].[MeasurementTransfer] pre processing done'

    END -- (SELECT COUNT(*) FROM [Core].[MeasurementTransfer]) >0
    /*  End Check if old data exists. This may happen if process stopped after the first commit part */

	 
    /* Regular processing starts here */
    DECLARE DaysToProcess CURSOR
    FOR
    SELECT DISTINCT Ts_Day
    FROM [Core].[Measurement]
    WHERE Ts_Day >= @measureMonthLowWaterMark
      AND Ts_Day <= @measureMonthHighWaterMark
      AND Ts_Day < CONVERT(DATE, DATEADD(DAY, -1, GETUTCDATE()))  -- Older than today
    ORDER BY 1 ASC;

    OPEN DaysToProcess  
  
    FETCH NEXT FROM DaysToProcess   
    INTO @Ts_Day

  

    DECLARE @TransferStepId bigint
    DECLARE @SwitchToTransferStepId bigint
  

    DECLARE @CheckConstraintSQL NVARCHAR(MAX)
           ,@EmptyTableName sysname       
           ,@TransferTableName sysname       
         


    WHILE @@FETCH_STATUS = 0  
    BEGIN 
      SET @PrintMessage = CONCAT('Process Ts_Day: ', @Ts_Day)
      EXEC [Helper].[Conditional_print] @PrintMessage

	  /* Only empty partitions can be split in when a columnstore index exists on the table. To avoid this problem, data is only moved if
	     there is a partition defined for the corresponding Ts_Day                                                                        */
	  DECLARE @MaxPartitionBorder DATE

      SELECT @MaxPartitionBorder = MAX(CONVERT(DATE, FromValue))
      FROM [Partition].[PartitionRangeValues]
      WHERE PartitionFunctionName = 'monthPartitionFunction'

      IF @Ts_Day >= @MaxPartitionBorder
        RAISERROR('Missing partition. Please check [Partition].[PartitionRangeValues] and run [Partition].[MaintainPartitionBorders] accordingly', 15, 1);



	  SET @StartTime = GETUTCDATE()
	  SET @StepParameterValues = 'Ts_Day = ' + CONVERT(VARCHAR, @Ts_Day)

	  -- If day partitions are merged together, then data may be transferred in an earlier step
      IF (SELECT COUNT(*) 
        FROM [Core].[Measurement]
	    WHERE  [Ts_Day] = @Ts_Day ) = 0
      BEGIN
        SET @PrintMessage = CONCAT('No Rows to transfer (earlier partition merge) Ts_Day: ', @Ts_Day)
        EXEC [Helper].[Conditional_print] @PrintMessage
	    EXEC [Logging].[StartStep] @TaskId, 'No Rows to transfer (earlier partition merge)', @StepParameterValues, @StepId =   @TransferStepId output
	    EXEC [Logging].[EndStep] @TransferStepId, 'End', NULL

      END
      ELSE
      BEGIN
        EXEC [Helper].[Conditional_print] 'Copy data to MeasurementStore (CDMS)'
	    EXEC [Logging].[StartStep] @TaskId, 'Copy data to MeasurementStore (CDMS)', @StepParameterValues, @StepId =   @TransferStepId output

        SELECT @Partition_Number   = $PARTITION.dayPartitionFunction(@Ts_Day)
        EXEC [Logging].[StartStep] @TaskId, 'CDMS, Switch partition to MeasurementTransfer', @StepParameterValues, @StepId =   @SwitchToTransferStepId output
	    BEGIN TRANSACTION

          EXEC [Helper].[Conditional_print] 'Switch data from [Measurement] to [MeasurementTransfer]'
          -- Switch data from [Measurement] to [MeasurementTransfer] 
          SET @SQL = CONCAT('ALTER TABLE [Core].[Measurement] SWITCH PARTITION ', @Partition_Number, ' TO [Core].[MeasurementTransfer] PARTITION ',  @Partition_Number)
          EXEC sp_executesql @SQL

        COMMIT
	    EXEC [Logging].[EndStep] @SwitchToTransferStepId, 'End', NULL

	 
	    BEGIN TRANSACTION
           EXEC [Helper].[Conditional_print] 'Move Data From MeasurementTransfer to MeasurementStore] '
  	       EXEC [Core].[MoveDataFromTransferToStore] @TaskId=@TaskId, @DropHistoryTable=@DropHistoryTable

	    COMMIT

	    EXEC [Logging].[EndStep] @TransferStepId, 'End', NULL
    
	  END --  Records must be transferred
	
	  FETCH NEXT FROM DaysToProcess   
      INTO @Ts_Day

      SET @PrintMessage = CONCAT('Process Ts_Day: ', @Ts_Day, ' ... done')
      EXEC [Helper].[Conditional_print] @PrintMessage

    END -- While loop


    CLOSE DaysToProcess;
    DEALLOCATE DaysToProcess;

    EXEC [Logging].[EndTask]  @TaskId, 'End', NULL

  END TRY
  /*********************************************************************/
  BEGIN CATCH

	DECLARE @PrintText VARCHAR(255)
    SET @PrintText = CONCAT('Exception catched; Procedure = ', OBJECT_NAME(@@PROCID), '; @StartTrancount=', @StartTrancount, '; @@TRANCOUNT = ', @@TRANCOUNT)
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
	  SELECT @ErrorMessage=ERROR_MESSAGE();
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

  SELECT 0 AS ReturnDataSet

END