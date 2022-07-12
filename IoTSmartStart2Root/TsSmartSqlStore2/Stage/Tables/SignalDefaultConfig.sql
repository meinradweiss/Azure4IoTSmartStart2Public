CREATE TABLE [Stage].[SignalDefaultConfig] (
    [SignalDefaultConfigGId]  UNIQUEIDENTIFIER NOT NULL,
    [SignalDefaultConfigId]   INT              NOT NULL,
    [Measurand]               NVARCHAR (256)   NOT NULL,
    [UpdateLatestMeasurement] BIT              NOT NULL,
    [SetCreatedAt]            BIT              NOT NULL,
    [CreatedAt]               DATETIME2 (3)    NOT NULL
);

