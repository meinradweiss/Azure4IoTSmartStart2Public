CREATE VIEW [MartPowerBI].[LatestMeasurement]
AS

SELECT       *
			,DATEDIFF(MILLISECOND, [Ts], [CreatedAt]) AS EndToEndLatencyMs
			,DATEDIFF(SECOND,      [Ts], [CreatedAt]) AS EndToEndLatencyS
FROM [Core].[LatestMeasurement]