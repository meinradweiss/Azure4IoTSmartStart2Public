
CREATE VIEW [MartPowerBI].[LatestMeasurement]
AS

SELECT       [SignalId]
            ,[Ts]                                                                                                                             AS [Ts_UTC]                                                                                               
            ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE  COALESCE(CONVERT(NVARCHAR, [SystemConfig].[SystemConfigValue])
	                                                                            ,'Central European Standard Time'))                           AS [Ts]
            ,[MeasurementValue]
            ,[MeasurementText]
            ,[MeasurementContext]
            ,[LatestMeasurement].[CreatedAt]
			,DATEDIFF(MILLISECOND, [Ts], [LatestMeasurement].[CreatedAt])                      AS EndToEndLatencyMs
			,DATEDIFF(SECOND,      [Ts], [LatestMeasurement].[CreatedAt])                      AS EndToEndLatencyS
		    ,COALESCE(CONVERT(NVARCHAR, [SystemConfig].[SystemConfigValue])
	                                   ,'Central European Standard Time')                      AS [Ts_Timezone]
FROM [Core].[LatestMeasurement]    
LEFT OUTER JOIN [Config].[SystemConfig] 
  ON [SystemConfig].[SystemConfigName] = 'LocalTimezone'