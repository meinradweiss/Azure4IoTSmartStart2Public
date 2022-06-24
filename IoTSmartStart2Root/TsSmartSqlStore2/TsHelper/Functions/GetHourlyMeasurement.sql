CREATE FUNCTION [TsHelper].[GetHourlyMeasurement] (@SignalId INT
                                                  , @FromTs   DATETIME2(3) 
												  , @ToTs     DATETIME2(3)
													)
RETURNS @HourlyMeasurement TABLE (
	[SignalId] [int]                 NOT NULL,
	[TimeWindowStart] [datetime2](3) NOT NULL,
	[TimeWindowEnd] [datetime2](3)   NOT NULL,
	[WeightedAverage] [float]        NOT NULL,
	[NumberOfRealValues] [int]       NOT NULL,
	[MinimalValue] [real]            NOT NULL,
	[MaximalValue] [real]            NOT NULL,
	[MinimalRealValue] [real] NULL,
	[MaximalRealValue] [real] NULL
) 
AS
BEGIN

  -- Compact, integrated version, faster but less insights

  DECLARE @WINDOWDURATION INT = 3600000

  DECLARE @FromTs_Day DATETIME = CONVERT(DATE, @FromTs)
         ,@ToTs_Day   DATETIME = CONVERT(DATE, @ToTs)

  DECLARE @LastKnowTsAtOrLowerFromTs DateTime2(3)
   
  -- Check if there is data at or bevore the start datetime
  SELECT @LastKnowTsAtOrLowerFromTs = MAX(Ts)
  FROM [Core].[AllMeasurement]
  WHERE Ts <= @FromTs
    AND SignalId = @SignalId;


  IF @LastKnowTsAtOrLowerFromTs is null
    RETURN


  DECLARE @LastKnownMeasurementPerHour TABLE
  (
     SignalId         INT          NOT NULL
	,Ts_Day           DATETIME NOT NULL
	,hourToProcess    DATETIME NOT NULL
	,Ts               DATETIME2(3) NOT NULL
	,MeasurementValue REAL         NOT NULL
  )


  INSERT INTO @LastKnownMeasurementPerHour
    SELECT *
    FROM   [TsHelper].[LastKnownMeasurementPerHour] MaxLastKnownMeasurementPerHour
    WHERE   MaxLastKnownMeasurementPerHour.SignalId =  @SignalId
  	  AND   Ts                                      >= @LastKnowTsAtOrLowerFromTs
	  AND   Ts_Day                                  >= CONVERT(DATETIME,@LastKnowTsAtOrLowerFromTs)
	  AND   Ts                                      <= @ToTs
	  AND   Ts_Day                                  <= @ToTs_Day


  INSERT INTO  @HourlyMeasurement 
   SELECT @SignalId                                                       AS SignalId
        ,TimeWindowStart 
	    ,DATEADD(MILLISECOND, @WINDOWDURATION, TimeWindowStart)           AS TimeWindowEnd
        ,SUM(LastMeasurementValue * EventDuration) / @WINDOWDURATION      AS WeightedAverage
	    ,SUM(RealValue)                                                   AS NumberOfRealValues 
		,MIN(LastMeasurementValue)                                        AS MinimalValue
		,MAX(LastMeasurementValue)                                        AS MaximalValue
		,MIN(case when RealValue = 0 then null else MeasurementValue end) AS MinimalRealValue
		,MAX(case when RealValue = 0 then null else MeasurementValue end) AS MaximalRealValue
  FROM
  ( SELECT *
   ,DATEDIFF(MILLISECOND, LastTs      , Ts)              as EventDuration
	FROM 
    (
     SELECT  * 
       , LAG(Ts, 1,ts)                             OVER (PARTITION BY TimeWindowStart  ORDER BY Ts) AS LastTs
       , LAG(MeasurementValue, 1,MeasurementValue) OVER (PARTITION BY TimeWindowStart  ORDER BY Ts) AS LastMeasurementValue
     FROM 
     (
        --	 Project last known value to the start of the window, if there is no value at this point in time
        SELECT  [HourTimeWindowSlot].[TimeWindowStart]
              , [HourTimeWindowSlot].[TimeWindowStart] AS Ts
              , [LastKnownEnd].[MeasurementValue]
			  , 0 as RealValue
        FROM [TsHelper].[HourTimeWindowSlot] 
          LEFT OUTER JOIN [Core].[AllMeasurement]
      	   ON  [AllMeasurement].Ts_Day   = [HourTimeWindowSlot].[TimeWindowStart_day] 
      	   AND [AllMeasurement].Ts       = [HourTimeWindowSlot].[TimeWindowStart]
      	   AND [AllMeasurement].SignalId = @SignalId
        INNER JOIN [Core].[AllMeasurement] LastKnownEnd
             ON LastKnownEnd.SignalId = @SignalId
      	   AND LastKnownEnd.Ts = (SELECT MAX(Ts)
      	                          FROM   @LastKnownMeasurementPerHour as x
      							  WHERE  x.Ts     < [HourTimeWindowSlot].[TimeWindowStart]
      							 )
        WHERE [AllMeasurement].Ts  IS NULL    -- No values for end
          AND TimeWindowStart >= @FromTs
          AND TimeWindowEnd   <= @ToTs
        
      
     UNION ALL

         --	 Project a record to the TimeWindowEnd. It is only there to calculate the duration of the last slot
         SELECT  [HourTimeWindowSlot].[TimeWindowStart]
              ,  [HourTimeWindowSlot].[TimeWindowEnd]   AS Ts
              , 0 -- Meaningless [LastKnownEnd].[MeasurementValue]
			  , 0 as RealValue
         FROM [TsHelper].[HourTimeWindowSlot] 
        WHERE TimeWindowStart >= @FromTs
          AND TimeWindowEnd   <=  @ToTs
      
      
      UNION ALL
      
	     ---- Read the real Measurements and join it to the timeslot
         SELECT  [HourTimeWindowSlot].[TimeWindowStart]
               , [Ts]
               , [AllMeasurement].[MeasurementValue]
			  , 1 as RealValue
         FROM  [Core].[AllMeasurement]
           INNER JOIN [TsHelper].[HourTimeWindowSlot] 
      	      ON [Ts] >= [TimeWindowStart] 
			 AND [Ts] <  [TimeWindowEnd]
         WHERE   [SignalId]              =       @SignalId
         	   AND [AllMeasurement].Ts_Day  BETWEEN @FromTs_Day AND @ToTs_Day
      	       AND [AllMeasurement].Ts      >= @FromTs     
			   AND [AllMeasurement].Ts       < @ToTs
 
       ) AS FullDataset     					    
     ) AS ExtendedFullDataset
   ) AS ExtendedFullDatasetWithDuration
   WHERE EventDuration <> 0 or RealValue = 1
   GROUP BY TimeWindowStart

   RETURN
END
