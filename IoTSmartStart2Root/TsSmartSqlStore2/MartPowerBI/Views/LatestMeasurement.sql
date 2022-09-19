

CREATE VIEW [MartPowerBI].[LatestMeasurement]
AS

SELECT       [SignalId]
            ,[Ts]                                                                             AS [Ts_UTC]    
			,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE  TargetTimeZone) AS [Ts]
            ,[MeasurementValue]
            ,[MeasurementText]
            ,[MeasurementContext]
            ,[LatestMeasurement].[CreatedAt]
			,DATEDIFF(MILLISECOND, [Ts], [LatestMeasurement].[CreatedAt])                      AS [EndToEndLatencyMs]
			,DATEDIFF(SECOND,      [Ts], [LatestMeasurement].[CreatedAt])                      AS [EndToEndLatencyS]
		    ,TargetTimeZone                                                                    AS [Ts_Timezone]
FROM [Core].[LatestMeasurement]    
  CROSS JOIN [Config].[TargetTimeZone]