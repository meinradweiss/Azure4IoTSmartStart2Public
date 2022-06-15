CREATE TABLE [Logging].[StepLog] (
    [StepId]              BIGINT        DEFAULT (NEXT VALUE FOR [Logging].[LogSequence]) NOT NULL,
    [TaskId]              BIGINT        NOT NULL,
    [StepName]            NVARCHAR (255) NOT NULL,
    [StartTime]           DATETIME2 (7) NOT NULL,
    [EndTime]             DATETIME2 (7) NULL,
    [ExecutionParameters] NVARCHAR (MAX) NULL,
    [Status]              NVARCHAR (64)  NOT NULL,
    [ErrorDetails]        NVARCHAR (MAX) NULL,
    [CreatedBy]           [sysname]     NOT NULL,
    [CreatedAt]           DATETIME      NOT NULL,
    [UpdatedAt]           DATETIME      NULL,
    CONSTRAINT [PK_Logging_StepLog] PRIMARY KEY CLUSTERED ([StepId] ASC),
    CHECK ([Status]='Error' OR [Status]='End' OR [Status]='Start'),
    CONSTRAINT [FK_Logging_StepLog_TaskLog] FOREIGN KEY ([TaskId]) REFERENCES [Logging].[TaskLog] ([TaskId])
);

