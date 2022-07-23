

CREATE FUNCTION [Mart].[GetMeasurementForRelativeTimeWindow] 
  (  @DeltaTime       VARCHAR(25)
    ,@EndDateTime     DATETIME2(3) 
	,@DefaultTimeZone VARCHAR(50) = 'Central European Standard Time' 
  )
RETURNS TABLE
AS 
RETURN 


With [GetMeasurement]
as
(
  SELECT [Ts]                                                                                                  AS [Ts_UTC]
        ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @DefaultTimeZone)                     AS [Ts]
        ,[Ts_Day]                                                                                              AS [Ts_Day_PartitionKey_UTC]
        ,[SignalId]
        ,[MeasurementValue]
        ,[MeasurementText]
		,CONVERT(INT, CONVERT(VARCHAR, [Ts], 112))                                                              AS [Ts_Day_UTC]
		-- CONVERT(VARCHAR(12) is required to be able to zoom in PowerBI below seconds
        ,CONVERT(VARCHAR(12),  CONVERT(TIME(3), Ts, 121))                                                       AS [Ts_Time_UTC]
		,CONVERT(INT,      CONVERT(VARCHAR, CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @DefaultTimeZone, 112))  AS [Ts_Day]
		---- CONVERT(VARCHAR(12) is required to be able to zoom in PowerBI below seconds
		,CONVERT(VARCHAR(12), CONVERT(time(3), CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @DefaultTimeZone))    AS [Ts_Time]

  FROM  [Core].[AllMeasurement]
    CROSS JOIN [Mart].[GetRelativeTimeWindow] (@DeltaTime, @EndDateTime, @DefaultTimeZone)
  WHERE [Ts_Day] >= [UtcTs_DayStartDate] 
    AND [Ts_Day] <= [UtcTs_DayEndDate]
    AND [Ts]     >= [UtcStartDateTime]
    AND [Ts]     <= [UtcEndDateTime]
)
select 
        [Ts_UTC]
	   ,[Ts]
	   ,[Ts_Day_PartitionKey_UTC]
	   ,[SignalId]
       ,[MeasurementValue]
       ,[MeasurementText]
	   
	   ,[Ts_Day_UTC]
	   ,[Ts_Time_UTC]

	   ,[Ts_Day]
	   ,[Ts_Time]
	   ,LEFT([Ts_Time],2) AS [Ts_Hour]
	   ,SUBSTRING([Ts_Time],4,2) AS [Ts_Minute]
	   ,SUBSTRING([Ts_Time],7,2) AS [Ts_Second]
	   ,SUBSTRING([Ts_Time],10,3) AS [Ts_Millisecond]
from [GetMeasurement]
GO
