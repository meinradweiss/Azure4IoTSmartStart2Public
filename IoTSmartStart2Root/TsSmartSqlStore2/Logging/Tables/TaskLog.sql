CREATE TABLE [Logging].[TaskLog] (
    [TaskId]              BIGINT        DEFAULT (NEXT VALUE FOR [Logging].[LogSequence]) NOT NULL,
    [TaskName]            NVARCHAR (255)  NOT NULL,
    [StartTime]           DATETIME2 (7)   NOT NULL,
    [EndTime]             DATETIME2 (7)   NULL,
    [ExecutionParameters] NVARCHAR (MAX)  NULL,
    [Status]              NVARCHAR (64)    NOT NULL,
    [ErrorDetails]        NVARCHAR (MAX)   NULL,
    [CreatedBy]           [sysname]       NOT NULL,
    [CreatedAt]           DATETIME        NOT NULL,
    [UpdatedAt]           DATETIME        NULL,
    CONSTRAINT [PK_Logging_TaskLog] PRIMARY KEY CLUSTERED ([TaskId] ASC),
    CHECK ([Status]='Error' OR [Status]='End' OR [Status]='Start')
);

