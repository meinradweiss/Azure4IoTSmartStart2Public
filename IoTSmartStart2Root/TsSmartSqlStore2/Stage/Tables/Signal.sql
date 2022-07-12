CREATE TABLE [Stage].[Signal] (
    [SignalGId]               UNIQUEIDENTIFIER NOT NULL,
    [SignalId]                INT              NOT NULL,
    [SignalName]              NVARCHAR (256)   NOT NULL,
    [DeviceId]                NVARCHAR (256)   NOT NULL,
    [Measurand]               NVARCHAR (256)   NOT NULL,
    [UpdateLatestMeasurement] BIT              DEFAULT ((0)) NOT NULL,
    [SetCreatedAt]            BIT              DEFAULT ((0)) NOT NULL,
    [CreatedAt]               DATETIME2 (3)    DEFAULT (getutcdate()) NOT NULL
);

