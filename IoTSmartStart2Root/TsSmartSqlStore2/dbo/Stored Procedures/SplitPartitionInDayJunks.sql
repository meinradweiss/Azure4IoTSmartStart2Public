
CREATE PROCEDURE [dbo].[SplitPartitionInDayJunks] (@partitionBaseName sysname
  , @dayAheadNumber int = 30
  , @startDate datetime = NULL)
AS
BEGIN
  -- Code moved to [Partition] schema
  -- This procedure should no longer be used, it's only there for backward compatability

  EXEC [Partition].[SplitPartitionInDayJunks] @partitionBaseName, @dayAheadNumber, @startDate
END