CREATE TABLE [Core].[MeasurementDuplicateKey] (
    [Ts]                  DATETIME2 (3)   NOT NULL,
    [Ts_Day]              INT             NOT NULL,
    [SignalId]            INT             NOT NULL,
    [MeasurementValue]    REAL            NULL,
    [MeasurementText]     NVARCHAR (2000) NULL,
    [MeasurementContext]  NVARCHAR (2000) NULL,      -- Allow to store special context information. Best used as JSON Container
    [CreatedAt]           DATETIME2 (3)   DEFAULT (getdate()) NULL,
    CONSTRAINT [FK_Core_MeasurementDuplicateKey_Signal] FOREIGN KEY ([SignalId]) REFERENCES [Core].[Signal] ([SignalId])

)ON [dayPartitionScheme] ([Ts_Day]);


GO

CREATE CLUSTERED INDEX [IX_MeasurementDuplicateKey_SignalId_Ts_Ts_Day] ON [Core].[MeasurementDuplicateKey] ([SignalId] ASC, [Ts] DESC, [Ts_Day] DESC) WITH (DATA_COMPRESSION = PAGE, STATISTICS_INCREMENTAL  = ON) ON [dayPartitionScheme] ([Ts_Day])


 
