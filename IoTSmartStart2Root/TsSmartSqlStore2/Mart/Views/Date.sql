
CREATE VIEW [Mart].[Date] 
AS

WITH 
[TenList] 
AS 
(             SELECT   0 AS [Id]
  UNION ALL   SELECT   1 AS [Id]
  UNION ALL   SELECT   2 AS [Id]
  UNION ALL   SELECT   3 AS [Id]
  UNION ALL   SELECT   4 AS [Id]
  UNION ALL   SELECT   5 AS [Id]
  UNION ALL   SELECT   6 AS [Id]
  UNION ALL   SELECT   7 AS [Id]
  UNION ALL   SELECT   8 AS [Id]
  UNION ALL   SELECT   9 AS [Id]
)
, [FullList] 
AS
(
  SELECT   (([One].[Id] + [Ten].[Id] * 10) + [Hundred].[Id] * 100) + [Thousand].[Id] * 1000 AS [Number]
  FROM         TenList AS [One] 
   CROSS JOIN  TenList AS [Ten] 
   CROSS JOIN  TenList AS [Hundred] 
   CROSS JOIN  TenList AS [Thousand]
)
, [Startdate] 
AS
(
  SELECT   CONVERT(DATE, '2019-01-01') AS [Startdate]
)
, [DateList] 
AS
(
  SELECT   DATEADD(DAY, [FullList].number, STARTDATE.Startdate) AS datum
  FROM         [Startdate] AS Startdate 
    CROSS JOIN [FullList] AS [FullList]
)
   
  SELECT   datum                                       AS DateId
		  ,CONVERT(DATETIME, CONVERT(DATE, datum)) AS [Ts_Day]
          ,DATEPART(YEAR,    datum)      AS Year
              , DATEPART(MONTH,   datum) AS Month
              , DATEPART(WEEKDAY, datum) AS Weekday
              , DATEPART(WEEK,    datum) AS Week
              , DATEPART(DAY,    datum)  AS DayShort
              , Right('0' + Convert(varchar, DATEPART(DAY,    datum)),2)
                + '.' + Right('0' + Convert(varchar, DATEPART(month,    datum)),2)
                + '.' + Convert(varchar, DATEPART(year,    datum))
                                          AS Day
     FROM         [DateList] AS [DateList_1]
     WHERE     (DATEPART(YEAR, datum) <= DATEPART(YEAR, GETUTCDATE()))