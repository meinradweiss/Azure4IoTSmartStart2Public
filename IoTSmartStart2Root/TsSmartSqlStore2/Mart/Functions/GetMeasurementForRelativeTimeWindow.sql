

CREATE FUNCTION [Mart].[GetMeasurementForRelativeTimeWindow] 
  (  @DeltaTime        VARCHAR(25)
    ,@EndDateTime_UTC  DATETIME2(3) 
	,@TargetTimeZone   VARCHAR(50) = 'Central European Standard Time' 
  )
RETURNS TABLE
AS 
RETURN 


With [GetMeasurement]
as
(
  SELECT [Ts]                                                                                                  AS [Ts_UTC]
        ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @TargetTimeZone)                      AS [Ts]
        ,[Ts_Day]                                                                                              AS [Ts_Day_UTC]
        ,[SignalId]
        ,[MeasurementValue]
        ,[MeasurementText]
        ,CONVERT(VARCHAR(12),  CONVERT(TIME(3), [Ts], 121))                                                    AS [Ts_Time_UTC]
		,CONVERT(INT,      CONVERT(VARCHAR, CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @TargetTimeZone, 112))  AS [Ts_Day]
		---- CONVERT(VARCHAR(12) is required to be able to zoom in PowerBI below seconds
		,CONVERT(VARCHAR(12), CONVERT(time(3), CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @TargetTimeZone))    AS [Ts_Time]

  FROM  [Core].[AllMeasurement]
    CROSS JOIN [Mart].[GetRelativeTimeWindow] (@DeltaTime, @EndDateTime_UTC, @TargetTimeZone) AS GRTW
  WHERE [Ts_Day] >= GRTW.[Ts_DayStartDate_UTC] 
    AND [Ts_Day] <= GRTW.[Ts_DayEndDate_UTC]
    AND [Ts]     >= GRTW.[StartDateTime_UTC]
    AND [Ts]     <= GRTW.[EndDateTime_UTC]
)
SELECT 
        [Ts_UTC]
	   ,[Ts]
	   ,[SignalId]
       ,[MeasurementValue]
       ,[MeasurementText]
	   
	   ,[Ts_Day_UTC]
	   ,[Ts_Time_UTC]

	   ,[Ts_Day]
	   ,[Ts_Time]
	   ,LEFT([Ts_Time],2) AS [Ts_Hour]
	   ,SUBSTRING([Ts_Time],4,2)  AS [Ts_Minute]
	   ,SUBSTRING([Ts_Time],7,2)  AS [Ts_Second]
	   ,SUBSTRING([Ts_Time],10,3) AS [Ts_Millisecond]
	   ,@TargetTimeZone           AS [Ts_Timezone]
FROM [GetMeasurement]
GO

