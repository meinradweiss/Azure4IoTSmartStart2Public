CREATE TABLE [Core].[MeasurementDuplicateKey] (
    [Ts]               DATETIME2 (3)   NOT NULL,
    [Ts_Day]           DATETIME2 (0)   NOT NULL,
    [SignalId]         INT             NOT NULL,
    [MeasurementValue] REAL            NULL,
    [MeasurementText]  NVARCHAR (4000) NULL,
    [CreatedAt]        DATETIME2 (3)   DEFAULT (getdate()) NULL,
    CONSTRAINT [FK_Core_MeasurementDuplicateKey_Signal] FOREIGN KEY ([SignalId]) REFERENCES [Core].[Signal] ([SignalId])

)ON [dayPartitionScheme] ([Ts_Day]);


GO

CREATE CLUSTERED INDEX [IX_MeasurementDuplicateKey_SignalId_Ts_Ts_Day] ON [Core].[MeasurementDuplicateKey] ([SignalId] ASC, [Ts] DESC, [Ts_Day] DESC) WITH (DATA_COMPRESSION = PAGE) ON [dayPartitionScheme] ([Ts_Day])


 
