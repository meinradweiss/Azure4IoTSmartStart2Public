
CREATE VIEW [TsHelper].[LastKnownMeasurementPerHour]
AS

   SELECT HM.SignalId, HM.Ts_Day, HM.hourToProcess, M.Ts, M.MeasurementValue
   FROM
     (SELECT SignalId
	       , Ts_Day
		   , CONVERT(DATETIME2(0) ,LEFT(CONVERT(VARCHAR,Ts, 120),13) + ':00:00') as hourToProcess
		   , MAX(ts) AS TheTs
      FROM  [Core].[AllMeasurement] 
      GROUP BY SignalId, Ts_Day, CONVERT(DATETIME2(0) ,LEFT(CONVERT(VARCHAR,Ts, 120),13) + ':00:00')
     ) AS HM
     INNER JOIN [Core].[AllMeasurement]  AS M
       ON HM.SignalId = M.SignalId
   	AND HM.Ts_Day = M.Ts_Day
   	AND HM.TheTs  = M.Ts