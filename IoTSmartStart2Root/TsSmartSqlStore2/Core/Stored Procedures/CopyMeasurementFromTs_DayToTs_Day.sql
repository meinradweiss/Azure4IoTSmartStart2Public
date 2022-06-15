


CREATE PROCEDURE [Core].[CopyMeasurementFromTs_DayToTs_Day] @FromTs_Day       DATE 
                                                          ,@MoveDays          INT
                                                          ,@OffsetMillisecond INT = 0
														  ,@MaxNumberOfRows   INT = 100000000

AS
BEGIN

  ;WITH MeasurementsToCopy
  AS
  (
    SELECT DATEADD(MILLISECOND, @OffsetMillisecond, DATEADD(DAY, @MoveDays, [Ts])) AS [Ts]
          ,[SignalId]
  		,[MeasurementValue]
  		,[MeasurementText]
    FROM [Core].[AllMeasurement]
    WHERE Ts_Day = @FromTs_Day
      
  )
  INSERT INTO [Ingest].[Measurement] ([Ts], [SignalId], [MeasurementValue], [MeasurementText])
  SELECT TOP(@MaxNumberOfRows) [Ts], [SignalId], [MeasurementValue], [MeasurementText]
  FROM   MeasurementsToCopy

END