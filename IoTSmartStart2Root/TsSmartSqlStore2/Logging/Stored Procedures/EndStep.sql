CREATE PROCEDURE [Logging].[EndStep] 
      @StepId                BIGINT
    , @Status                NVARCHAR(64)  
    , @ErrorDetails          NVARCHAR(MAX)
 
AS  
    SET NOCOUNT ON;  

    UPDATE [StepLog] 
    SET [Status]             = @Status
       ,[ErrorDetails]       = @ErrorDetails
       ,[EndTime]            = GETUTCDATE()
       ,[UpdatedAt]          = GETUTCDATE()
    FROM [Logging].[StepLog]
    WHERE [StepId] = @StepId