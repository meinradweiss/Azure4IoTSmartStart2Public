CREATE PROCEDURE [Logging].[StartStep] 
      @TaskId                BIGINT
    , @StepName              NVARCHAR(255)  
    , @ExecutionParameters   NVARCHAR(MAX)
    , @StepId                BIGINT            OUTPUT  
AS  
    SET NOCOUNT ON;  

    DECLARE @newStepId BIGINT;

    SET @newStepId  = NEXT VALUE FOR [Logging].[LogSequence];


    INSERT INTO [Logging].[StepLog] 
    (
      [StepId]              
    , [TaskId]
    , [StepName]               
    , [StartTime]                   
    , [ExecutionParameters] 
    , [Status]                 
    , [CreatedBy]           
    , [CreatedAt]           
    )
    SELECT 
           @newStepId
         , @TaskId
         , @StepName 
         , GETUTCDATE()       -- StartTime
         , @ExecutionParameters
         ,'START'
         , SYSTEM_USER
         , GETUTCDATE();       -- ValidFrom
    SET  @StepId = @newStepId;