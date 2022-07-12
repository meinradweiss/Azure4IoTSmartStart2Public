CREATE TABLE [Stage].[Measurement] (
    [Ts]                 DATETIME2 (3)   NOT NULL,
    [Ts_Day]             INT             NOT NULL,
    [SignalId]           INT             NOT NULL,
    [MeasurementValue]   REAL            NULL,
    [MeasurementText]    NVARCHAR (2000) NULL,
    [MeasurementContext] NVARCHAR (2000) NULL,
    [CreatedAt]          DATETIME2 (3)   NULL
) ON [dayPartitionScheme] ([Ts_Day])
WITH (DATA_COMPRESSION = PAGE)


GO
CREATE CLUSTERED INDEX [NCIX_StageMeasurementTs_Day]
    ON [Stage].[Measurement]([Ts_Day] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [dayPartitionScheme] ([Ts_Day]);

