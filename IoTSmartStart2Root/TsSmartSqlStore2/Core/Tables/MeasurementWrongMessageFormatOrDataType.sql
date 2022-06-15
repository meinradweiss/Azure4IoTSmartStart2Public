CREATE TABLE [Core].[MeasurementWrongMessageFormatOrDataType] (
    [Ts]                      DATETIME2 (3)                       NULL,
    [SignalId]                INT                                 NULL,
    [SignalName]              NVARCHAR (256)                      NULL,   
    [MeasurementValue]        REAL                                NULL,
    [MeasurementText]         NVARCHAR (4000)                     NULL,
    [SourceTS]                NVARCHAR (MAX)                      NULL,
    [SourceMeasurementValue]  NVARCHAR (MAX)                      NULL,
    [SourceMeasurementText]   NVARCHAR (MAX)                      NULL,
    [SourceMessage]           NVARCHAR (MAX)                  NOT NULL,
    [CreatedAt]               DATETIME2 (3) DEFAULT GETUTCDATE() NOT NULL
);


GO

CREATE CLUSTERED INDEX [IX_CoreMeasurementWrongMessageFormatOrDataType_CreatedAt] ON [Core].[MeasurementWrongMessageFormatOrDataType] ([CreatedAt]);
GO
