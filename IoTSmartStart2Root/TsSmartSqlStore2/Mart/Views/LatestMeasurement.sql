
CREATE VIEW [Mart].[LatestMeasurement]
AS

SELECT       [LatestMeasurement].[Ts]
            ,[LatestMeasurement].[MeasurementValue]
            ,[LatestMeasurement].[MeasurementText]
            ,[LatestMeasurement].[CreatedAt]
			,DATEDIFF(MILLISECOND, [LatestMeasurement].[Ts], [LatestMeasurement].[CreatedAt]) AS EndToEndLatencyMs
			,DATEDIFF(SECOND, [LatestMeasurement].[Ts], [LatestMeasurement].[CreatedAt])      AS EndToEndLatencyS
            ,[Signal].[SignalId]
            ,[Signal].[SignalName]
            ,[Signal].[DeviceId] 
            ,[Signal].[Measurand]
FROM [Core].[LatestMeasurement]     AS LatestMeasurement
  INNER JOIN [Core].[Signal]     AS Signal
    ON [LatestMeasurement].[SignalId] = Signal.[SignalId]