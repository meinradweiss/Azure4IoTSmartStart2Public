CREATE TABLE [Stage].[Measurement] (
    [Ts]                 DATETIME2 (3)   NOT NULL,
    [Ts_Day]             DATETIME        NOT NULL,
    [SignalId]           INT             NOT NULL,
    [MeasurementValue]   REAL            NULL,
    [MeasurementText]    NVARCHAR (4000) NULL,
    [MeasurementContext] NVARCHAR (4000) NULL,
    [CreatedAt]          DATETIME2 (3)   NULL
) ON [dayPartitionScheme] ([Ts_Day])
WITH (DATA_COMPRESSION = PAGE)


GO
CREATE CLUSTERED INDEX [NCIX_StageMeasurementTs_Day]
    ON [stage].[Measurement]([Ts_Day] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [dayPartitionScheme] ([Ts_Day]);

