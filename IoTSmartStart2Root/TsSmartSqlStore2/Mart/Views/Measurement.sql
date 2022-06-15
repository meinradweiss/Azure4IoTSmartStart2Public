



CREATE VIEW [Mart].[Measurement]
AS
SELECT       [Measurement].[Ts]
            ,[Measurement].[Ts_Day]
            ,[Measurement].[MeasurementValue]
            ,[Measurement].[MeasurementText]
            ,[Signal].[SignalId]
            ,[Signal].[SignalName]
            ,[Signal].[DeviceId] 
            ,[Signal].[Measurand]
FROM [Core].[AllMeasurement]     AS Measurement 
  INNER JOIN [Core].[Signal]     AS Signal
    ON Measurement.[SignalId] = Signal.[SignalId]