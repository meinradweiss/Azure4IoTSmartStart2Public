


CREATE PROCEDURE [TsHelper].[SynchronizeHourTimeWindowSlot](@FromTs Datetime
  														   ,@ToTs Datetime)
AS
BEGIN

   -- Usage: EXEC [TsHelper].[SynchronizeHourTimeWindowSlot] '2019-01-01', '2021-12-31'

   SET NOCOUNT ON

   ;WITH TimeWindowSlot
   AS
   (
      SELECT TimeWindowStart, TimeWindowEnd
      FROM (SELECT DATEADD(HOUR, ROW_NUMBER() OVER (ORDER BY A.object_id) -1, @FromTs ) TimeWindowStart
                  ,DATEADD(HOUR, ROW_NUMBER() OVER (ORDER BY A.object_id)   , @FromTs ) TimeWindowEnd
            FROM sys.objects         AS A
              CROSS JOIN sys.objects AS B) AS X
      WHERE TimeWindowStart <= @ToTs

   )

   MERGE [TsHelper].[HourTimeWindowSlot] AS HWS
   USING TimeWindowSlot                  AS WS
      ON HWS.TimeWindowStart = WS.TimeWindowStart
   WHEN NOT MATCHED BY TARGET THEN
     INSERT   (TimeWindowStart
	         , TimeWindowEnd
			 , TimeWindowStart_day
			 , TimeWindowEnd_day) 
	   VALUES (WS.TimeWindowStart
	         , WS.TimeWindowEnd
			 ,CONVERT(DATE, WS.TimeWindowStart)
			 ,CONVERT(DATE, WS.TimeWindowend)
			  )
   WHEN NOT MATCHED BY SOURCE THEN
     DELETE; 
END