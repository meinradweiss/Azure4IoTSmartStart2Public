CREATE TABLE [Core].[Measurement] (
    [Ts]               DATETIME2 (3)   NOT NULL,
    [Ts_Day]           DATETIME2 (0)   NOT NULL,
    [SignalId]         INT             NOT NULL,
    [MeasurementValue] REAL            NULL,
    [MeasurementText]  NVARCHAR (4000) NULL,
    [CreatedAt]        DATETIME2 (3)   NULL,
    CONSTRAINT [PK_Core_Measurement] PRIMARY KEY CLUSTERED ([SignalId] ASC, [Ts] DESC, [Ts_Day] DESC) WITH (DATA_COMPRESSION = PAGE) ON [dayPartitionScheme] ([Ts_Day]),
    CONSTRAINT [FK_Core_Measurement_Signal] FOREIGN KEY ([SignalId]) REFERENCES [Core].[Signal] ([SignalId])
) ON [dayPartitionScheme] ([Ts_Day]);

