

CREATE FUNCTION [Mart].[GetPivotHumidityTemperature](
       @FromTs    Datetime2(3)  
      ,@ToTs      Datetime2(3)  
      ,@DeviceId  NVARCHAR(256) = '%'
      )
RETURNS TABLE
AS

  /* Usage
     SELECT *
     FROM  [Mart].[GetPivotHumidityTemperature]('2022-03-03 13:53:10:00','2022-03-03 13:53:25:00', DEFAULT)
     ORDER BY TS
           
     SELECT *
     FROM  [Mart].[GetPivotHumidityTemperature]('2022-03-03 13:53:10:00','2022-03-03 13:53:25:00', 'M%')
     ORDER BY TS
  */


RETURN
  WITH DataToPivot
  AS
  (
    SELECT [Ts]
          --,CONVERT(DATETIME2(0),[Ts]) AS [Ts]
          ,[DeviceId]
  		,[Measurand]
  		,[MeasurementValue]
    FROM [Mart].[Measurement]
    WHERE [Measurand] IN ('Humidity'
    					   ,'Temperature'
    					   ,'Dummy')
  	AND [Ts]       >=   @FromTs
  	AND [Ts_Day]   >=   CONVERT(INT, CONVERT(VARCHAR, @FromTs, 112)) 
  	AND [Ts]       <=   @ToTs
  	AND [Ts_Day]   <=   CONVERT(INT, CONVERT(VARCHAR, @ToTs,   112)) 
  	AND [DeviceId] LIKE @DeviceId
  )
  SELECT *
  FROM DataToPivot
  PIVOT(
      AVG([MeasurementValue]) 
      FOR [Measurand] 
  	    IN ([Humidity] 
             ,[Temperature] 
             ,[Dummy])
  ) AS pivot_table;