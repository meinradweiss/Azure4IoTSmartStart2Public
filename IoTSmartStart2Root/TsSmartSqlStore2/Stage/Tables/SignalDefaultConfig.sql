CREATE TABLE [stage].[SignalDefaultConfig] (
    [SignalDefaultConfigGId]  UNIQUEIDENTIFIER NOT NULL,
    [SignalDefaultConfigId]   INT              NOT NULL,
    [Measurand]               NVARCHAR (256)   NULL,
    [UpdateLatestMeasurement] BIT              NOT NULL,
    [SetCreatedAt]            BIT              NOT NULL,
    [CreatedAt]               DATETIME2 (3)    NOT NULL
);

