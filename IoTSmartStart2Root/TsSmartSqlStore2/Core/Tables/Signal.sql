CREATE TABLE [Core].[Signal] (
    [SignalGId]               UNIQUEIDENTIFIER DEFAULT NEWID()                      NOT NULL,
    [SignalId]                INT              DEFAULT (NEXT VALUE FOR [Core].[Id]) NOT NULL,
    [SignalName]              NVARCHAR (256)                                        NOT NULL,
    [DeviceId]                NVARCHAR (256)                                        NOT NULL,
    [Measurand]               NVARCHAR (256)                                        NOT NULL,
    [UpdateLatestMeasurement] BIT                                                   NOT NULL DEFAULT 0,
    [SetCreatedAt]            BIT                                                   NOT NULL DEFAULT 0,
    -- Add your additional attributes, as needed
    [CreatedAt]         DATETIME2 (3)    DEFAULT GETUTCDATE() NOT NULL,
    PRIMARY KEY NONCLUSTERED ([SignalGId] ASC),
    CONSTRAINT [Core_Signal] UNIQUE NONCLUSTERED ([SignalId] ASC), 
    CONSTRAINT [UK_CoreSignal_SignalName] UNIQUE([SignalName])
);


GO
CREATE CLUSTERED INDEX [CIX_Core_Signal_SignalId]
    ON [Core].[Signal]([SignalId] ASC);
GO

CREATE TRIGGER [Core].[CoreSignal_IU]
    ON [Core].[Signal]
    FOR INSERT, UPDATE
    AS
    BEGIN
        SET NoCount ON

        -- Create row in [Core].[LatestMeasurement] if [UpdateLatestMeasurement] = 1
        INSERT INTO [Core].[LatestMeasurement] ([SignalId], [Ts])
        SELECT DISTINCT Inserted.[SignalId], GETUTCDATE()
        FROM inserted
        LEFT OUTER JOIN [Core].[LatestMeasurement] 
          ON Inserted.[SignalId] = [LatestMeasurement].[SignalId]
        WHERE [UpdateLatestMeasurement] = 1
          AND [LatestMeasurement].[SignalId] IS NULL;

        -- Remove row in [Core].[LatestMeasurement] if [UpdateLatestMeasurement] = 0
        DELETE [LatestMeasurement]
        FROM [Core].[LatestMeasurement]
        INNER JOIN inserted
          ON [LatestMeasurement].[SignalId] = inserted.[SignalId]
        WHERE inserted.[UpdateLatestMeasurement] = 0

        -- Set the value accrding to the last known record
        UPDATE [LatestMeasurement]
          SET [LatestMeasurement].[MeasurementValue] = [LatestArrivedMeasurement].[MeasurementValue]
             ,[LatestMeasurement].[MeasurementText]  = [LatestArrivedMeasurement].[MeasurementText]
             ,[LatestMeasurement].[Ts]               = [LatestArrivedMeasurement].[Ts] 
        FROM [Core].[LatestMeasurement]
        INNER JOIN inserted
          ON [LatestMeasurement].[SignalId] = inserted.[SignalId]
        INNER JOIN (SELECT [Measurement].[SignalId]
                         , [Ts]
                         , [MeasurementValue]
                         , [MeasurementText] 
        			FROM [Core].[Measurement]
        			  INNER JOIN (SELECT [SignalId], MAX(Ts) as [LastTimestamp]
        			              FROM [Core].[Measurement]
        			              GROUP BY [SignalId]) AS [LastMeasurement]
        			  ON [Measurement].[SignalId]  = [LastMeasurement].[SignalId]
        			  AND [Measurement].[Ts]       = [LastMeasurement].[LastTimestamp]
        			  AND [Measurement].[Ts_Day]   = CONVERT(INT, CONVERT(VARCHAR, LastMeasurement.[LastTimestamp], 112))
                   ) AS [LatestArrivedMeasurement]
        ON [LatestMeasurement].[SignalId] = [LatestArrivedMeasurement].[SignalId]

    END
GO

CREATE TRIGGER [Core].[CoreSignal_D]
    ON [Core].[Signal]
    FOR DELETE
    AS
    BEGIN
        SET NoCount ON

        -- Remove row in [Core].[LatestMeasurement] 
        DELETE [LatestMeasurement]
        FROM [Core].[LatestMeasurement]
        INNER JOIN deleted
          ON [LatestMeasurement].[SignalId] = deleted.[SignalId]


    END
GO