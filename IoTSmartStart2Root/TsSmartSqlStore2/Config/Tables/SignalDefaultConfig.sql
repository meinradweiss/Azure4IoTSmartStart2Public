CREATE TABLE [Config].[SignalDefaultConfig]
(
    [SignalDefaultConfigGId]  UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID ()           NOT NULL,
    [SignalDefaultConfigId]   INT              DEFAULT (NEXT VALUE FOR [Core].[Id]) NOT NULL,
    [Measurand]               NVARCHAR (256)                                        NOT NULL,
    [UpdateLatestMeasurement] BIT                                                   NOT NULL,
    [SetCreatedAt]            BIT                                                   NOT NULL,
    [CreatedAt]               DATETIME2 (3)    DEFAULT GETUTCDATE() NOT NULL,
    PRIMARY KEY NONCLUSTERED ([SignalDefaultConfigGId] ASC),
    CONSTRAINT [Core_SignalDefaultConfig]                      UNIQUE NONCLUSTERED ([SignalDefaultConfigId] ASC), 
    CONSTRAINT [UK_CoreSignalDefaultConfig_Measurand] UNIQUE                       ([Measurand])
);
go

CREATE CLUSTERED INDEX [CIX_Config_SignalDefaultConfig_SignalId]
    ON [Config].[SignalDefaultConfig]([SignalDefaultConfigId] ASC);
GO



CREATE TRIGGER [Config].[SignalDefaultConfig_IU]
    ON [Config].[SignalDefaultConfig]
    FOR INSERT, UPDATE
    AS
    BEGIN
        SET NoCount ON

        UPDATE [Signal]
          SET [Signal].[UpdateLatestMeasurement] = MeasurandConfig.[UpdateLatestMeasurement]
             ,[Signal].[SetCreatedAt]            = MeasurandConfig.[SetCreatedAt]
        FROM [Core].[Signal] AS [Signal]
          INNER JOIN [Config].[SignalDefaultConfig] AS MeasurandConfig
            ON [Signal].[Measurand] = MeasurandConfig.[Measurand]
        INNER JOIN INSERTED
            ON  [Signal].[Measurand]  = INSERTED.[Measurand]

    END
GO

