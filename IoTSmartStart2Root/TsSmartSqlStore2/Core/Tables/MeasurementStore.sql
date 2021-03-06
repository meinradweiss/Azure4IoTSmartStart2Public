CREATE TABLE [Core].[MeasurementStore] (
    [Ts]               DATETIME2 (3)   NOT NULL,
    [Ts_Day]           DATETIME2 (0)   NOT NULL,
    [SignalId]         INT             NOT NULL,
    [MeasurementValue] REAL            NULL,
    [MeasurementText]  NVARCHAR (4000) NULL,
    [CreatedAt]        DATETIME2 (3)   NULL
) ON [monthPartitionScheme] ([Ts_Day]);


GO

CREATE NONCLUSTERED INDEX [NCIX_CoreMeasurementStoreSignalIdTs_Day]
    ON [Core].[MeasurementStore]([SignalId] ASC, [Ts_Day] ASC)  WITH (DATA_COMPRESSION = PAGE)
    ON [monthPartitionScheme] ([Ts_Day]);
GO

CREATE NONCLUSTERED INDEX [NCIX_CoreMeasurementStoreTsTs_DaySignalId]
    ON [Core].[MeasurementStore]([Ts] ASC, [Ts_Day] ASC, [SignalId] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [monthPartitionScheme] ([Ts_Day]);


GO
CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Core_MeasurementStore]
    ON [Core].[MeasurementStore]
    ON [monthPartitionScheme] ([Ts_Day]);

