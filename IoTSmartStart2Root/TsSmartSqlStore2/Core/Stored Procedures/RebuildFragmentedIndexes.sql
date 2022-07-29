


CREATE PROCEDURE [Core].[RebuildFragmentedIndexes] (@FragmentationLimit FLOAT        = 80.0
                                                  ,@SchemaName         sysname      = 'Core'
                                                  ,@DaysToConsider     INT          = 3
                                                  ,@EndDateTime_UTC    DATETIME2(3) = NULL)
AS
BEGIN


SET NOCOUNT ON

DECLARE @RebuildIndex CURSOR;

DECLARE @TaskId BIGINT
DECLARE @TaskParameterValues NVARCHAR(max)
SET @TaskParameterValues = concat('@FragmentationLimit = ', convert(varchar, @FragmentationLimit), ', @SchemaName = ', convert(varchar, @SchemaName), ', @DaysToConsider = ', convert(varchar, @DaysToConsider), ', @EndDateTime_UTC = ', convert(varchar, @EndDateTime_UTC))
EXEC [Logging].[StartTask]  'RebuildFragmentedIndexes', @TaskParameterValues, @TaskId =   @TaskId output

DECLARE @TableSchemaName              sysname
	  , @TableName                    sysname
	  , @partition_number             int
	  , @IndexName                    sysname
	  , @avg_fragmentation_in_percent float

SET @RebuildIndex = CURSOR FOR

select TableSchemaName, TableName, partition_number, IndexName, avg_fragmentation_in_percent
from [Core].[GetIndexFragmentation] (@DaysToConsider, @EndDateTime_UTC)
WHERE  TableSchemaName = @SchemaName
  AND  avg_fragmentation_in_percent >= @FragmentationLimit;

DECLARE @StepId bigint
DECLARE @StepParameterValues NVARCHAR(max)

OPEN @RebuildIndex

FETCH NEXT FROM @RebuildIndex 
  INTO   @TableSchemaName              
	   , @TableName                    
	   , @partition_number             
	   , @IndexName                    
	   , @avg_fragmentation_in_percent 

DECLARE @SQLString nvarchar(max)

WHILE @@fetch_status = 0
  BEGIN
	  SET @SQLString =  'ALTER INDEX   [' + @IndexName + '] ON [' + @TableSchemaName + '].[' + @TableName + '] '
      SET @SQLString += 'REBUILD Partition = ' + convert(varchar, @partition_number) + ' WITH (ONLINE=ON);'

      SET @StepParameterValues = @SQLString
	  EXEC [Logging].[StartStep] @TaskId, 'RebuildIndex', @StepParameterValues, @StepId =   @StepId output

	  EXEC [Helper].[Conditional_sp_executesql_print] @SQLString

	  EXEC [Logging].[EndStep] @StepId, 'End', NULL

      FETCH NEXT FROM @RebuildIndex 
		  INTO   @TableSchemaName              
			   , @TableName                    
			   , @partition_number             
			   , @IndexName                    
			   , @avg_fragmentation_in_percent 
  END

 CLOSE @RebuildIndex
 DEALLOCATE @RebuildIndex

 EXEC [Logging].[EndTask]  @TaskId, 'End', NULL

 SELECT 0 AS ReturnDataSet

END