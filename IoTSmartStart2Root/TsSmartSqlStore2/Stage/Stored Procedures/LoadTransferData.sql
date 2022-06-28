

CREATE PROCEDURE [Stage].[LoadTransferData]   @From_Ts_Day                 DATETIME = '1900.01.01'   -- Ts_Day >=
                                            , @To_Ts_Day                   DATETIME = '9999.12.31'   -- Ts_Day <=
											, @HighWaterMarkMeasuremtStore DATETIME = '1900.01.01'   -- Ts_Day <=

AS

BEGIN



  SET NOCOUNT ON
  SET XACT_ABORT OFF
  SET DATEFORMAT YMD 

  DECLARE @StartTrancount INT
   SET @StartTrancount = @@TRANCOUNT

  DECLARE @PrintMessage NVARCHAR(MAX)
  DECLARE @SQLString    NVARCHAR(max)

  DECLARE @TaskId BIGINT
  DECLARE @TaskParameterValues NVARCHAR(max)
  SET @TaskParameterValues = '@From_Ts_Day  = '  + convert(varchar, @From_Ts_Day ) 
                         + ', @To_Ts_Day = ' + convert(varchar, @To_Ts_Day) 
						 + ', @HighWaterMarkMeasuremtStore = '          + convert(varchar, @HighWaterMarkMeasuremtStore) 
  EXEC [Logging].[StartTask]  'LoadTransferData', @TaskParameterValues, @TaskId =   @TaskId output

  DECLARE @StepParameterValues NVARCHAR(max)
		 ,@Ts_Day              DATETIME

  BEGIN TRY

    DECLARE @CopyStepId      BIGINT
	DECLARE @FeedbackMessage NVARCHAR(MAX)

    -- Copy new SignalDefaultConfig rows to [Config].[SignalDefaultConfig]
    -- existing rows will not be adjusted

	SET @StepParameterValues = 'none, copy all new data';

    EXEC [Logging].[StartStep] @TaskId, 'Copy data from [Stage].[SignalDefaultConfig] to [Config].[SignalDefaultConfig]', @StepParameterValues, @StepId =   @CopyStepId output

    INSERT INTO [Config].[SignalDefaultConfig]
             ([SignalDefaultConfigGId]
             ,[SignalDefaultConfigId]
             ,[Measurand]
             ,[UpdateLatestMeasurement]
             ,[SetCreatedAt]
             ,[CreatedAt])
    SELECT    [SignalDefaultConfigGId]
             ,[SignalDefaultConfigId]
             ,[Measurand]
             ,[UpdateLatestMeasurement]
             ,[SetCreatedAt]
             ,[CreatedAt]
    FROM [Stage].[SignalDefaultConfig] AS S
    WHERE NOT EXISTS (SELECT 'X' FROM [Config].[SignalDefaultConfig] AS T WHERE S.Measurand = T.Measurand);

	SET @FeedbackMessage = CONCAT('Rows copied: ',@@rowcount);

 	EXEC [Logging].[EndStep] @CopyStepId, 'End', @FeedbackMessage


  
    -- Copy new Signal rows to [Core].[Signal]
    -- existing rows will not be adjusted

    EXEC [Logging].[StartStep] @TaskId, 'Copy data from [Stage].[Signal] to [Core].[Signal]', @StepParameterValues, @StepId =   @CopyStepId output


    INSERT INTO [Core].[Signal]
             ([SignalGId]
             ,[SignalId]
             ,[SignalName]
             ,[DeviceId]
             ,[Measurand]
             ,[UpdateLatestMeasurement]
             ,[SetCreatedAt]
             ,[CreatedAt])
    SELECT    [SignalGId]
			 ,[SignalId]
			 ,[SignalName]
			 ,[DeviceId]
			 ,[Measurand]
			 ,[UpdateLatestMeasurement]
			 ,[SetCreatedAt]
   			 ,[CreatedAt]
    FROM [Stage].[Signal] AS S
    WHERE NOT EXISTS (SELECT 'X' FROM [Core].[Signal] AS T WHERE S.[SignalGId] = T.[SignalGId])
   
	SET @FeedbackMessage = CONCAT('Rows copied: ',@@rowcount);

 	EXEC [Logging].[EndStep] @CopyStepId, 'End', @FeedbackMessage

	--- Reset Sequence

	EXEC [Logging].[StartStep] @TaskId, 'Reset [Core].[Id]', @StepParameterValues, @StepId =   @CopyStepId output

	DECLARE @NextSequenceId INT 

	SELECT @NextSequenceId = IsNull(MAX(SignalId),0) + 1
	FROM [Core].[Signal]

	SET @SQLString = CONCAT('ALTER SEQUENCE [Core].[Id] RESTART WITH ', @NextSequenceId,';')
	EXEC [Helper].[Conditional_sp_executesql_print] @SQLString

	SET @FeedbackMessage = CONCAT('New start value of SEQUENCE [Core].[Id]: ',@NextSequenceId);
 	EXEC [Logging].[EndStep] @CopyStepId, 'End', @FeedbackMessage

    -- Copy Measurement data to [Core].[Measurement]
    DECLARE DaysToProcess CURSOR
    FOR
    SELECT DISTINCT Ts_Day
    FROM [Stage].[Measurement]
    WHERE Ts_Day >= @From_Ts_Day 
      AND Ts_Day <= @To_Ts_Day
    ORDER BY 1 DESC;

    OPEN DaysToProcess  
  
    FETCH NEXT FROM DaysToProcess   
    INTO @Ts_Day

    DECLARE @TransferStepId bigint

    WHILE @@FETCH_STATUS = 0  
    BEGIN 
      SET @PrintMessage = CONCAT('Copy data for Ts_Day: ', @Ts_Day)
      EXEC [Helper].[Conditional_print] @PrintMessage

	  	       

	    BEGIN TRANSACTION


          SET @StepParameterValues = 'Ts_Day = ' + CONVERT(VARCHAR, @Ts_Day, 120)


		  IF (@Ts_Day <= @HighWaterMarkMeasuremtStore)
		  BEGIN

              EXEC [Logging].[StartStep] @TaskId, 'Copy data from [Stage].[Measurement] to [Core].[MeasurementStore]', @StepParameterValues, @StepId =   @TransferStepId output

		      INSERT INTO [Core].[MeasurementStore]
                       ([Ts]
                       ,[Ts_Day]
                       ,[SignalId]
                       ,[MeasurementValue]
                       ,[MeasurementText]
                       ,[MeasurementContext]
                       ,[CreatedAt])
             SELECT     s.[Ts]
                       ,s.[Ts_Day]
                       ,s.[SignalId]
                       ,s.[MeasurementValue]
                       ,s.[MeasurementText]
                       ,s.[MeasurementContext]
                       ,s.[CreatedAt]
             FROM [Stage].[Measurement] AS s
		       LEFT OUTER JOIN [Core].[MeasurementStore] AS t
			     ON s.[Ts]       = t.[Ts]
			    AND s.[Ts_Day]   = t.[Ts_Day]
			    AND s.[SignalId] = t.[SignalId]
			  WHERE s.[Ts_Day]   = @Ts_Day
			    AND t.[SignalId] IS NULL                      -- Only new rows

            SET @FeedbackMessage = CONCAT('Rows copied to [Core].[MeasurementStore]: ',@@rowcount);
		  END
		  ELSE
		  BEGIN

           EXEC [Logging].[StartStep] @TaskId, 'Copy data from [Stage].[Measurement] to [Core].[Measurement]', @StepParameterValues, @StepId =   @TransferStepId output

           INSERT INTO [Core].[Measurement]
                       ([Ts]
                       ,[Ts_Day]
                       ,[SignalId]
                       ,[MeasurementValue]
                       ,[MeasurementText]
                       ,[MeasurementContext]
                       ,[CreatedAt])
             SELECT     s.[Ts]
                       ,s.[Ts_Day]
                       ,s.[SignalId]
                       ,s.[MeasurementValue]
                       ,s.[MeasurementText]
                       ,s.[MeasurementContext]
                       ,s.[CreatedAt]
             FROM [Stage].[Measurement] AS s
		       LEFT OUTER JOIN [Core].[Measurement] AS t
			     ON s.[Ts]       = t.[Ts]
			    AND s.[Ts_Day]   = t.[Ts_Day]
			    AND s.[SignalId] = t.[SignalId]
			  WHERE s.[Ts_Day]   = @Ts_Day
			    AND t.[SignalId] IS NULL                      -- Only new rows
		    
	        SET @FeedbackMessage = CONCAT('Rows copied to [Core].[Measurement]: ',@@rowcount); 
           END

  	      EXEC [Logging].[EndStep] @TransferStepId, 'End', @FeedbackMessage

        COMMIT
 

    

	
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