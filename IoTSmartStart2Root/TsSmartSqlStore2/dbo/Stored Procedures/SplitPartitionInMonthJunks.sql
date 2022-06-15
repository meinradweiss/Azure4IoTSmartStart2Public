
CREATE PROCEDURE [dbo].[SplitPartitionInMonthJunks] (@partitionBaseName sysname
  , @dayAheadNumber int = 120
  , @startDate datetime = NULL)
AS
BEGIN
  -- Code moved to [Partition] schema
  -- This procedure should no longer be used, it's only there for backward compatability

  EXEC [Partition].[SplitPartitionInMonthJunks] @partitionBaseName, @dayAheadNumber, @startDate

END