
CREATE VIEW  [Ingest].[MeasurementWithSignalName]
AS
  --Ingest Facade

  SELECT
	 CONVERT(datetime2(3), NULL)   AS [Ts]
	,CONVERT(NVARCHAR (256), NULL) AS [SignalName]    -- Business Key of [Core].[Signal]
	,CONVERT(NVARCHAR (256), NULL) AS [DeviceId] 
	,CONVERT(NVARCHAR (256), NULL) AS [Measurand]
	,[MeasurementValue] 
    ,[MeasurementText]
    ,[MeasurementContext]
  FROM [Core].[Measurement]
GO



  
CREATE TRIGGER [Ingest].[IngestMeasurementWithSignalNameInsteadOfInsertTrigger]
ON [Ingest].[MeasurementWithSignalName]
  INSTEAD OF INSERT
AS

  SET NOCOUNT ON;


  -- Insert missing signal name into Signal table
  INSERT INTO [Core].[Signal] 
  (
     [SignalName]
    ,[DeviceId] 
    ,[Measurand]
    ,[UpdateLatestMeasurement]
    ,[SetCreatedAt]          
  )
  SELECT DISTINCT INSERTED.[SignalName]
                 ,INSERTED.[DeviceId] 
                 ,INSERTED.[Measurand]
                 ,COALESCE(MeasurandConfig.[UpdateLatestMeasurement], 0)
                 ,COALESCE(MeasurandConfig.[SetCreatedAt],            0)
  FROM INSERTED
    LEFT OUTER JOIN [Config].[SignalDefaultConfig] AS MeasurandConfig
      ON INSERTED.[Measurand] = MeasurandConfig.[Measurand]

  WHERE NOT EXISTS (SELECT 'X' FROM [Core].[Signal] AS s WHERE s.[SignalName] = INSERTED.[SignalName]);


  -- Copy events to regular Measurement ingest facade
  INSERT INTO  [Ingest].[Measurement]
  (
     [Ts] 
	,[SignalId] 
	,[MeasurementValue] 
    ,[MeasurementText]
    ,[MeasurementContext]
  )
  SELECT [Ts]
        ,[SignalId]
        ,[MeasurementValue] 
        ,[MeasurementText]
        ,[MeasurementContext]
  FROM INSERTED AS i
  INNER JOIN [Core].[Signal]  AS s
    ON	i.[SignalName] = s.[SignalName];

GO