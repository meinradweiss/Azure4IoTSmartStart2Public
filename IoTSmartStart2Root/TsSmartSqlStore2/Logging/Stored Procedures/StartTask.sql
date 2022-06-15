CREATE PROCEDURE [Logging].[StartTask] 
      @TaskName              NVARCHAR(255)  
    , @ExecutionParameters   NVARCHAR(MAX)
    , @TaskId                BIGINT            OUTPUT  
AS  
    SET NOCOUNT ON;  

    DECLARE @newTaskId BIGINT;

    SET @newTaskId  = NEXT VALUE FOR [Logging].[LogSequence];


    INSERT INTO [Logging].[TaskLog] 
    (
         [TaskId]                
       , [TaskName]             
       , [StartTime]             
       , [ExecutionParameters]       
       , [Status]                
       , [CreatedBy]             
       , [CreatedAt]             
    )
    SELECT 
           @newTaskId
         , @TaskName 
         , GETUTCDATE()       -- StartTime
         , @ExecutionParameters
         ,'START'
         , SYSTEM_USER
         , GETUTCDATE();       -- ValidFrom
         

    SET  @TaskId = @newTaskId;