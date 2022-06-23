CREATE FUNCTION [TsHelper].[GetExtendedHourlyMeasurement] (@SignalId INT
                                                         , @FromTs   DATETIME2(3) 
														 , @ToTs     DATETIME2(3)
														  )
RETURNS @HourlyMeasurement TABLE (
	[TimeWindowStart]      [datetime2](3) NOT NULL,
	[Ts]                   [datetime2](3) NOT NULL,
	[MeasurementValue]     [real]         NOT NULL,
	[RealValue]            [int]          NOT NULL,
	[LastTS]               [datetime2](3) NOT NULL,
	[LastMeasurementValue] [real]         NOT NULL,
	[EventDuration]        [int]          NOT NULL
) 

AS
BEGIN

  DECLARE @WINDOWDURATION INT = 3600000

  DECLARE @FromTs_Day DATETIME2(0) = CONVERT(DATE, @FromTs)
         ,@ToTs_Day   DATETIME2(0) = CONVERT(DATE, @ToTs)

  DECLARE @LastKnowTsAtOrLowerFromTs DateTime2(3)
   
  -- Check if there is data at or before the start datetime
  SELECT @LastKnowTsAtOrLowerFromTs = MAX(Ts)
  FROM [Core].[AllMeasurement]
  WHERE Ts <= @FromTs
    AND SignalId = @SignalId;


  IF @LastKnowTsAtOrLowerFromTs is null
    RETURN


  DECLARE @LastKnownMeasurementPerHour TABLE
  (
     SignalId         INT          NOT NULL
	,Ts_Day           DATETIME2(0) NOT NULL
	,hourToProcess    DATETIME2(0) NOT NULL
	,Ts               DATETIME2(3) NOT NULL
	,MeasurementValue REAL         NOT NULL
  )


  INSERT INTO @LastKnownMeasurementPerHour
    SELECT *
    FROM   [TsHelper].[LastKnownMeasurementPerHour] MaxLastKnownMeasurementPerHour
    WHERE   MaxLastKnownMeasurementPerHour.SignalId =  @SignalId
  	  AND   Ts                                      >= @LastKnowTsAtOrLowerFromTs
	  AND   Ts_Day                                  >= CONVERT(DATETIME2(0), CONVERT(DATE, @LastKnowTsAtOrLowerFromTs))
	  AND   Ts                                      <= @ToTs
	  AND   Ts_Day                                  <= @ToTs_Day


  INSERT INTO  @HourlyMeasurement 
    SELECT *
   ,DATEDIFF(MILLISECOND, LastTS       , Ts)              as EventDuration
	FROM 
    (
     SELECT  * 
       , LAG(Ts, 1, Ts)                            OVER (PARTITION BY TimeWindowStart  ORDER BY Ts) AS LastTS
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

   RETURN
END
GO
