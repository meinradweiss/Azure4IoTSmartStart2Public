CREATE FUNCTION [Mart].[GetMeasurementForRelativeTimeWindowWithLastPointProjection] 
  (  @DeltaTime       VARCHAR(25)
    ,@EndDateTime     DATETIME2(3) 
	,@DefaultTimeZone VARCHAR(50) = 'Central European Standard Time' 
  )
RETURNS TABLE
AS 
RETURN 

  WITH BaseResultSet
  AS
  (
  SELECT [Ts]                                                                                                AS [Ts_UTC]
        ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @DefaultTimeZone)                   AS [Ts]
        ,[Ts_Day]                                                                                            AS [Ts_Day_PartitionKey_UTC]
        ,[SignalId]
        ,[MeasurementValue]
        ,[MeasurementText]
        ,CONVERT(DATETIME2(0), CONVERT(DATE, Ts))                                                                 AS [Ts_Day_UTC]
		-- CONVERT(VARCHAR(12) is required to be able to zoom in PowerBI below seconds
        ,CONVERT(VARCHAR(12), CONVERT(TIME(3), Ts, 121))                                                          AS [Ts_Time_UTC]
		,CONVERT(DATETIME2(0), CONVERT(DATE,        CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @DefaultTimeZone)) AS [Ts_Day]
		-- CONVERT(VARCHAR(12) is required to be able to zoom in PowerBI below seconds
		,CONVERT(VARCHAR(12), CONVERT(time(3), CONVERT(DATETIMEOFFSET, [Ts]) AT TIME ZONE @DefaultTimeZone)) AS [Ts_Time]

  FROM  [Core].[AllMeasurement]
    CROSS JOIN [Mart].[GetRelativeTimeWindow] (@DeltaTime, @EndDateTime, @DefaultTimeZone)
  WHERE [Ts_Day] >= [UtcTs_DayStartDate] 
    AND [Ts_Day] <= [UtcTs_DayEndDate]
    AND [Ts]     >= [UtcStartDateTime]
    AND [Ts]     <= [UtcEndDateTime]
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
         [NewTs]                                                                                                AS [Ts_UTC]
        ,CONVERT(DATETIME2(3),CONVERT(DATETIMEOFFSET, [NewTs]) AT TIME ZONE @DefaultTimeZone)                   AS [Ts]
        ,CONVERT(DATETIME2(0), CONVERT(DATE, NewTs))                                                            AS [Ts_Day_PartitionKey_UTC]
        ,[SignalId]
        ,[LastMeasurementValue]                                                                                 AS [MeasurementValue]
        ,[LastMeasurementText]                                                                                  AS [MeasurementText]
        ,CONVERT(DATETIME2(0), CONVERT(DATE, [NewTs]))                                                          AS [Ts_Day_UTC]
		-- CONVERT(VARCHAR(12) is required to be able to zoom in PowerBI below seconds
        ,CONVERT(VARCHAR(12),   CONVERT(TIME(3), [NewTs], 121))                                                 AS [Ts_Time_UTC]
		,CONVERT(DATETIME2(0), CONVERT(DATE, CONVERT(DATETIMEOFFSET, [NewTs]) AT TIME ZONE @DefaultTimeZone))   AS [Ts_Day]
		-- CONVERT(VARCHAR(12) is required to be able to zoom in PowerBI below seconds
		,CONVERT(VARCHAR(12), CONVERT(time(3), CONVERT(DATETIMEOFFSET, [NewTs]) AT TIME ZONE @DefaultTimeZone)) AS [Ts_Time]
    FROM ArtificialRecords
  )

  SELECT 
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
	   ,'RealMeasurement' as MeasurementType
  FROM  BaseResultSet
  UNION ALL
  SELECT 
        [AR].[Ts_UTC]
	   ,[AR].[Ts]
	   ,[AR].[Ts_Day_PartitionKey_UTC]
	   ,[AR].[SignalId]
       ,[AR].[MeasurementValue]
       ,[AR].[MeasurementText]
	   
	   ,[AR].[Ts_Day_UTC]
	   ,[AR].[Ts_Time_UTC]

	   ,[AR].[Ts_Day]
	   ,[AR].[Ts_Time]
	   ,LEFT([AR].[Ts_Time],2) AS [Ts_Hour]
	   ,SUBSTRING([AR].[Ts_Time],4,2) AS [Ts_Minute]
	   ,SUBSTRING([AR].[Ts_Time],7,2) AS [Ts_Second]
	   ,SUBSTRING([AR].[Ts_Time],10,3) AS [Ts_Millisecond]
		,'ArtificialMeasurement' as MeasurementType
        
  FROM  ArtificialRecordsWithTsColumns AS [AR]
  LEFT OUTER JOIN BaseResultSet                          -- Not needed, it there is already a datapoint
    ON  BaseResultSet.[Ts_UTC]  = [AR].[Ts_UTC]
	AND BaseResultSet.SignalId  = [AR].SignalId
  WHERE ([AR].[MeasurementValue] IS NOT NULL
      OR [AR].[MeasurementText]  IS NOT NULL)
	AND [BaseResultSet].[SignalId] IS  NULL
