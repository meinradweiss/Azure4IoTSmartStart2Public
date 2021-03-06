CREATE FUNCTION [Mart].[GetMeasurementForSignal] 
  (  @SignalId INT
    ,@FromTs   DATETIME2(3) 
    ,@ToTs     DATETIME2(3) 
    
  )
RETURNS TABLE
AS 
RETURN 

  SELECT *
  FROM  [Core].[AllMeasurement]
  WHERE [SignalId] = @SignalId
    AND [Ts_Day] >= CONVERT(DATETIME2(0), CONVERT(DATE, @FromTs)) 
    AND [Ts_Day] <= CONVERT(DATETIME2(0), CONVERT(DATE, @ToTs)) 
    AND [Ts]     >= @FromTs
    AND [Ts]     <= @ToTs

