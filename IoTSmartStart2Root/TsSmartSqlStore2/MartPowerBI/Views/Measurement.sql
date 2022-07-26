

CREATE VIEW [MartPowerBI].[Measurement]
AS

SELECT [Ts]                                                                                                                             AS [Ts_UTC]                                                                                               
      ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE  COALESCE(CONVERT(NVARCHAR, [SystemConfig].[SystemConfigValue])
	                                                                            ,'Central European Standard Time'))                     AS [Ts]
      ,CONVERT(INT, CONVERT(VARCHAR, CONVERT(DATE,CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE  COALESCE(CONVERT(NVARCHAR, [SystemConfig].[SystemConfigValue])
	                                                                            ,'Central European Standard Time')),112))               AS [Ts_Day]
	  ,[Ts_Day]                                                                                                                         AS [Ts_Day_UTC]      -- Use for partition elimination
      ,[SignalId]
      ,[MeasurementValue]
      ,[MeasurementText]
      ,[MeasurementContext]
      ,[AllMeasurement].[CreatedAt]
	  ,COALESCE(CONVERT(NVARCHAR, [SystemConfig].[SystemConfigValue])
	                                                                            ,'Central European Standard Time')                      AS [Ts_Timezone]
FROM [Core].[AllMeasurement]
LEFT OUTER JOIN [Config].[SystemConfig] 
  ON [SystemConfig].[SystemConfigName] = 'LocalTimezone'