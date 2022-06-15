

CREATE PROCEDURE [Core].[SpocTemplate](@TaskId BIGINT, @sql nvarchar(max))
AS
BEGIN
 SET XACT_ABORT OFF
 SET NOCOUNT ON

  DECLARE  @StepParameterValues NVARCHAR(max)
          ,@ThisStepId              INT

  SET @StepParameterValues = 'xxx HELPFUL INFO' 
  EXEC [Logging].[StartStep] @TaskId, 'xxxx StepName', @StepParameterValues, @StepId=@ThisStepId output

  DECLARE @TranCounter INT;  
  SET @TranCounter = @@TRANCOUNT;  
  IF @TranCounter > 0  
        -- Procedure called when there is an active transaction.  
        -- Create a savepoint to be able to roll back only the work done in the procedure if there is an  error.  
        SAVE TRANSACTION ProcedureSave;  
    ELSE  
        -- Procedure must start its own transaction.  
        BEGIN TRANSACTION;  


  BEGIN TRY
    select 'do work'
	exec sp_executesql @sql

    EXEC [Logging].[EndStep] @StepId=@ThisStepId, @Status='End', @ErrorDetails=NULL

    IF @TranCounter = 0  
            -- @TranCounter = 0 means no transaction was started before the procedure was called.  
            -- The procedure must commit the transaction it started.  
       COMMIT TRANSACTION;    
  END TRY  
  


  BEGIN CATCH  
        IF @TranCounter = 0  
            -- Transaction started in procedure.  
            -- Roll back complete transaction.  
            ROLLBACK TRANSACTION;  
        ELSE  
            -- Transaction started before procedure called, do not roll back modifications  
            -- made before the procedure was called.  
            IF XACT_STATE() <> -1  
                -- If the transaction is still valid, just roll back to the savepoint set at the  
                -- start of the stored procedure.  
                ROLLBACK TRANSACTION ProcedureSave;  
                -- If the transaction is uncommitable, a rollback to the savepoint is not allowed  
                -- because the savepoint rollback writes to the log. Just return to the caller, which  
                -- should roll back the outer transaction.  

	  DECLARE @LocalErrorNumber        INT
             ,@LocalErrorMessage       NVARCHAR(MAX)
             ,@LocalErrorSeverity      INT              
             ,@LocalErrorState         INT             
             ,@LocalErrorLine          INT             
  

      -- Preserve Error
      SELECT 
	   @LocalErrorNumber   = ERROR_NUMBER()   
      ,@LocalErrorSeverity = ERROR_SEVERITY() 
      ,@LocalErrorState    = ERROR_STATE()    
      ,@LocalErrorLine     = ERROR_LINE()     
      ,@LocalErrorMessage  = ERROR_MESSAGE()  


	  SET @LocalErrorMessage = N'Statement: ' + @sql + '; ERROR_NUMBER: ' + CONVERT(NVARCHAR, @LocalErrorNumber) + '; ERROR_LINE: ' + CONVERT(NVARCHAR, @LocalErrorLine) + '; ERROR_MESSAGE: ' + @LocalErrorMessage

	  EXEC [Logging].[EndStep]  @StepId=@ThisStepId, @Status='Error', @ErrorDetails=@LocalErrorMessage
	  RAISERROR(@LocalErrorMessage, @LocalErrorSeverity, @LocalErrorState);

    END CATCH 

END