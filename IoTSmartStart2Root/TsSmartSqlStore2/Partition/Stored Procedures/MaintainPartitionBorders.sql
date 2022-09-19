
CREATE PROCEDURE [Partition].[MaintainPartitionBorders] (@startDate DATETIME = NULL, @dayAheadNumber int = 35)
AS
BEGIN

  -- Keeps the day and month partition structure in sync
  -- Creates partitions starting with the first day of the month defined via @startDate 
  -- and the first day of the month following the date calculated with getdate() + @dayAheadNumber
  --
  -- e.g. @startDate = '2021-09-07', the current data is '2021-09-29' and  @dayAheadNumber int = 35 -> Partitions from 2021-09-01 to 2021-12-01
  --
  -- Usage: EXEC [Partition].[MaintainPartitionBorders]
  --          If no value is set for @startDate then the actual date will be used and 35 days added (plus rounded up to the next month) 
  
  SET NOCOUNT ON
  SET XACT_ABORT ON
  SET DATEFORMAT YMD

  DECLARE @StartDateFirstDayOfMonth   date
         ,@EndDateFirstDayOfNextMonth date
		 ,@DayAheadDate               date
		 ,@DaysInBetween              int

  
  IF @startDate IS NULL
    SET @startDate=GETUTCDATE()

  SET @DayAheadDate = DATEADD(DAY, @dayAheadNumber, GETUTCDATE())

  SET @StartDateFirstDayOfMonth   = CONVERT(DATE, LEFT(CONVERT(VARCHAR, @startDate, 112),6) + '01',112)
  SET @EndDateFirstDayOfNextMonth = DATEADD(MONTH, 1, CONVERT(DATE, LEFT(CONVERT(VARCHAR, @DayAheadDate, 112),6) + '01',112))
  SET @DaysInBetween              = DATEDIFF(DAY, @StartDateFirstDayOfMonth, @EndDateFirstDayOfNextMonth) + 1

  BEGIN TRANSACTION

    EXEC [Partition].[SplitPartitionInDayJunks] @partitionBaseName='dayPartition'
                                              , @startDate=@StartDateFirstDayOfMonth
	  										  , @dayAheadNumber= @DaysInBetween

    EXEC [Partition].[SplitPartitionInMonthJunks] @partitionBaseName='monthPartition'
                                                , @startDate=@StartDateFirstDayOfMonth
								    			, @dayAheadNumber= @DaysInBetween

  COMMIT 
 
  SELECT 0 AS ReturnDataSet
END
GO
