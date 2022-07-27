
CREATE FUNCTION [Mart].[GetMeasurementForRelativeTimeWindowWithLastPointProjection] 
  (  @DeltaTime       VARCHAR(25)
    ,@EndDateTime_UTC     DATETIME2(3) 
	,@TargetTimeZone VARCHAR(50) = 'Central European Standard Time' 
  )
RETURNS TABLE
AS 
RETURN 

  WITH BaseResultSet
  AS
  (

  SELECT [Ts]                                                                                                   AS [Ts_UTC]
        ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @TargetTimeZone)                      AS [Ts]
        ,[Ts_Day]                                                                                               AS [Ts_Day_UTC]
        ,[SignalId]
        ,[MeasurementValue]
        ,[MeasurementText]
        ,CONVERT(VARCHAR(12),  CONVERT(TIME(3), [Ts], 121))                                                     AS [Ts_Time_UTC]
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

  , ArtificialRecords
  AS
  (
  SELECT DateAdd(MILLISECOND,-1, [Ts_UTC]) AS                                             NewTs
        ,[SignalId]
        ,LEAD(MeasurementValue)  OVER (PARTITION BY SignalId ORDER BY Ts DESC)   AS LastMeasurementValue
        ,LEAD(MeasurementText)   OVER (PARTITION BY SignalId ORDER BY Ts DESC)   AS LastMeasurementText
  FROM  BaseResultSet
  )
  , ArtificialRecordsWithTsColumns
  AS
  (
     SELECT
         [NewTs]                                                                                                      AS [Ts_UTC]
        ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [NewTs]) AT TIME ZONE @TargetTimeZone)                         AS [Ts]
        ,CONVERT(INT, CONVERT(VARCHAR, CONVERT(DATE, NewTs),112))                                                     AS [Ts_Day_UTC]
        ,[SignalId]
        ,[LastMeasurementValue]                                                                                       AS [MeasurementValue]
        ,[LastMeasurementText]                                                                                        AS [MeasurementText]
        ,CONVERT(VARCHAR(12), CONVERT(TIME(3), [NewTs], 121))                                                         AS [Ts_Time_UTC]
		,CONVERT(INT,         CONVERT(VARCHAR, CONVERT(DATETIMEOFFSET, [NewTs]) AT TIME ZONE @TargetTimeZone, 112))  AS [Ts_Day]
		-- CONVERT(VARCHAR(12) is required to be able to zoom in PowerBI below seconds
		,CONVERT(VARCHAR(12), CONVERT(time(3), CONVERT(DATETIMEOFFSET, [NewTs]) AT TIME ZONE @TargetTimeZone))       AS [Ts_Time]
    FROM ArtificialRecords
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
	   ,LEFT([Ts_Time],2)         AS [Ts_Hour]
	   ,SUBSTRING([Ts_Time],4,2)  AS [Ts_Minute]
	   ,SUBSTRING([Ts_Time],7,2)  AS [Ts_Second]
	   ,SUBSTRING([Ts_Time],10,3) AS [Ts_Millisecond]
	   ,@TargetTimeZone          AS [Ts_Timezone]
	   ,'RealMeasurement' AS MeasurementType
  FROM  BaseResultSet
  UNION ALL
  SELECT 
        [AR].[Ts_UTC]
	   ,[AR].[Ts]
	   ,[AR].[SignalId]
       ,[AR].[MeasurementValue]
       ,[AR].[MeasurementText]
	   
	   ,[AR].[Ts_Day_UTC]
	   ,[AR].[Ts_Time_UTC]

	   ,[AR].[Ts_Day]
	   ,[AR].[Ts_Time]
	   ,LEFT([AR].[Ts_Time],2)         AS [Ts_Hour]
	   ,SUBSTRING([AR].[Ts_Time],4,2)  AS [Ts_Minute]
	   ,SUBSTRING([AR].[Ts_Time],7,2)  AS [Ts_Second]
	   ,SUBSTRING([AR].[Ts_Time],10,3) AS [Ts_Millisecond]
	   ,@TargetTimeZone               AS [Ts_Timezone]
	   ,'ArtificialMeasurement' AS MeasurementType
        
  FROM  ArtificialRecordsWithTsColumns AS [AR]
  LEFT OUTER JOIN BaseResultSet                          -- Not needed, it there is already a datapoint
    ON  BaseResultSet.[Ts_UTC]  = [AR].[Ts_UTC]
	AND BaseResultSet.SignalId  = [AR].SignalId
  WHERE ([AR].[MeasurementValue] IS NOT NULL
      OR [AR].[MeasurementText]  IS NOT NULL)
	AND [BaseResultSet].[SignalId] IS  NULL
