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
    AND [Ts_Day] >= CONVERT(INT, CONVERT(VARCHAR, @FromTs, 112)) 
    AND [Ts_Day] <= CONVERT(INT, CONVERT(VARCHAR, @ToTs,   112)) 
    AND [Ts]     >= @FromTs
    AND [Ts]     <= @ToTs

