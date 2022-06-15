
CREATE PROCEDURE [Partition].[SplitPartitionInDayJunks] (@partitionBaseName sysname
  , @dayAheadNumber int = 30
  , @startDate datetime = NULL)
AS
BEGIN

SET NOCOUNT ON

DECLARE @LowerBoundary DATETIME
IF @startDate is NULL
  SET @LowerBoundary = GETUTCDATE()
ELSE
  SET @LowerBoundary = @startDate

DECLARE @TaskId BIGINT
DECLARE @TaskParameterValues NVARCHAR(max)
SET @TaskParameterValues = '@partitionBaseName = ' + @partitionBaseName + ', @startDate = ' + CONVERT(VARCHAR, @LowerBoundary) + ' , @dayAheadNumber = ' + CONVERT(VARCHAR, @dayAheadNumber)
EXEC [Logging].[StartTask]  'SplitPartitionInDayJunks', @TaskParameterValues, @TaskId =   @TaskId output


DECLARE @AddSplits CURSOR;
DECLARE @SplitKey  DATE;

DECLARE @SQLString nVARCHAR(max)




SET @AddSplits = CURSOR FOR
--with PartitionRangesAheadList
--as
--(
--     SELECT convert(int, value) as DayAheadCounter 
--     FROM STRING_SPLIT(@dayAheadList, ',')
--)
--, DateList
WITH e1(n) AS
(
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
),                                              -- 10
e2(n) AS (SELECT 1 FROM e1 CROSS JOIN e1 AS b), -- 10 *     10 =     100
e3(n) AS (SELECT 1 FROM e1 CROSS JOIN e2),      -- 10 *    100 =   1'000
e4(n) AS (SELECT 1 FROM e1 CROSS JOIN e3),      -- 10 *  1'000 =  10'000
e5(n) AS (SELECT 1 FROM e1 CROSS JOIN e4)       -- 10 * 10'000 = 100'000
,PartitionRangesAheadList(DayAheadCounter)
AS (
  SELECT top (@dayAheadNumber) n = ROW_NUMBER()  OVER (ORDER BY n) -1 -- Zero Based
  FROM e5 
  ORDER BY n
), DateList
AS
(
    SELECT DayAheadCounter
         , DATEADD(DAY, DayAheadCounter, @LowerBoundary) AS thedate
    FROM PartitionRangesAheadList
), ExpectedSplitKeys
AS
(
select * , convert(DATE, thedate) as YearMonthDayBasedKey
from DateList
)
, ExistingSplitKey
AS
(
select value  as PartitionStartRange
FROM sys.partition_functions AS pf 
  INNER JOIN sys.partition_range_values AS pfrv
     ON PF.function_id = pfrv.function_id
     WHERE pf.name = 'dayPartitionFunction'
)
, MissingSplitRanges
AS
(
SELECT YearMonthDayBasedKey
FROM   ExpectedSplitKeys
  LEFT OUTER JOIN ExistingSplitKey
    ON ExpectedSplitKeys.YearMonthDayBasedKey = ExistingSplitKey.PartitionStartRange
where PartitionStartRange is null
)

SELECT *
FROM   MissingSplitRanges
ORDER BY YearMonthDayBasedKey

DECLARE @StepId bigint
DECLARE @StepParameterValues NVARCHAR(max)

OPEN @AddSplits

FETCH next FROM @AddSplits INTO @SplitKey

WHILE @@fetch_status = 0
  BEGIN

      set @StepParameterValues = CONVERT(VARCHAR, @SplitKey)
	  exec [Logging].[StartStep] @TaskId, 'CreatePartition', @StepParameterValues, @StepId =   @StepId output

      SET @SQLString =  'ALTER PARTITION SCHEME   ' + @partitionBaseName + 'Scheme NEXT USED [PRIMARY];'
      SET @SQLString += 'ALTER PARTITION FUNCTION ' + @partitionBaseName + 'Function() SPLIT RANGE(''' + CONVERT(VARCHAR, @SplitKey) + ''');'

      EXEC sp_executesql @statement = @SQLString ;
	  --PRINT @SQLString
	  exec [Logging].[EndStep] @StepId, 'End', NULL

      FETCH next FROM @AddSplits INTO @SplitKey
  END

 CLOSE @AddSplits
 DEALLOCATE @AddSplits

 EXEC [Logging].[EndTask]  @TaskId, 'End', NULL

END