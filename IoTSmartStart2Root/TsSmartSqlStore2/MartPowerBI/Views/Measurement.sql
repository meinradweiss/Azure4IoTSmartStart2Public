
CREATE VIEW [MartPowerBI].[Measurement]
AS

SELECT [Ts]                                                                                                                 AS [Ts_UTC]                                                                                               
      ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE  TargetTimeZone)                                     AS [Ts]
      ,CONVERT(INT, CONVERT(VARCHAR, CONVERT(DATE,CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE  TargetTimeZone),112))         AS [Ts_Day]
	  ,[Ts_Day]                                                                                                             AS [Ts_Day_UTC]          -- Use for partition elimination
      ,[SignalId]
      ,[MeasurementValue]
      ,[MeasurementText]
      ,[MeasurementContext]
      ,[AllMeasurement].[CreatedAt]                                                                                         AS [CreatedAt_UTC]
      ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [AllMeasurement].[CreatedAt]) AT TIME ZONE  TargetTimeZone)             AS [CreatedAt]
	  ,TargetTimeZone                                                                                                       AS [Ts_Timezone]
FROM [Core].[AllMeasurement]
  CROSS JOIN [Config].[TargetTimeZone]