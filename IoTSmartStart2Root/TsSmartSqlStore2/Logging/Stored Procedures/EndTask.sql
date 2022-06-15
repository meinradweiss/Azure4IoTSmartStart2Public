CREATE PROCEDURE [Logging].[EndTask] 
      @TaskId                BIGINT
    , @Status                NVARCHAR(64)  
    , @ErrorDetails          NVARCHAR(MAX)
 
AS  
    SET NOCOUNT ON;  

    UPDATE [TaskLog] 
    SET [Status]             = @Status
       ,[ErrorDetails]       = @ErrorDetails
       ,[EndTime]            = GETUTCDATE()
       ,[UpdatedAt]          = GETUTCDATE()
    FROM [Logging].[TaskLog]
    WHERE [TaskId] = @TaskId