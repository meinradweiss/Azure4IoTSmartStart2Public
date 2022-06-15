
CREATE FUNCTION [TsHelper].[GetHourlyMeasurementTwoStep] (@SignalId INT
                                                 , @FromTs   DATETIME2(3) 
								   			     , @ToTs     DATETIME2(3)
												  )
RETURNS TABLE
AS
  -- Allows access to the ExtendedHourlyMeasurement, but is less performant

  RETURN
  SELECT @SignalId                                                        AS SignalId
        ,TimeWindowStart 
	    ,DATEADD(MILLISECOND, 3600000, TimeWindowStart)                   AS TimeWindowEnd
        ,SUM(LastMeasurementValue * EventDuration) / 3600000              AS WeightedAverage
	    ,SUM(RealValue)                                                   AS NumberOfRealValues 
		,MIN(LastMeasurementValue)                                        AS MinimalValue
		,MAX(LastMeasurementValue)                                        AS MaximalValue
		,MIN(case when RealValue = 0 then null else MeasurementValue end) AS MinimalRealValue
		,MAX(case when RealValue = 0 then null else MeasurementValue end) AS MaximalRealValue
  FROM [TsHelper].[GetExtendedHourlyMeasurement] (@SignalId, @FromTs, @ToTs)
  WHERE EventDuration <> 0 or RealValue = 1
  GROUP BY TimeWindowStart