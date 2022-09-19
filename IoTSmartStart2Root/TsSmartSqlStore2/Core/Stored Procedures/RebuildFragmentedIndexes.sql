
CREATE PROCEDURE [Core].[RebuildFragmentedIndexes] (@FragmentationLimit FLOAT        = 80.0
                                                   ,@SchemaName         SYSNAME      = 'Core'
                                                   ,@TableName          SYSNAME      = 'Measurement'
                                                   ,@DaysToConsider     INT          = 5
                                                   ,@EndDateTime_UTC    DATETIME2(3) = NULL)
AS
BEGIN


SET NOCOUNT ON

DECLARE @RebuildIndex CURSOR;

DECLARE @TaskId BIGINT
DECLARE @TaskParameterValues NVARCHAR(max)
SET @TaskParameterValues = concat('@FragmentationLimit = ', convert(varchar, @FragmentationLimit), ', @SchemaName = ', convert(varchar, @SchemaName), ', @TableName = ', convert(varchar, @TableName), ', @DaysToConsider = ', convert(varchar, @DaysToConsider), ', @EndDateTime_UTC = ', convert(varchar, @EndDateTime_UTC))
EXEC [Logging].[StartTask]  'RebuildFragmentedIndexes', @TaskParameterValues, @TaskId =   @TaskId output

DECLARE @TableSchemaName              sysname
	  , @SelectedTableName                    sysname
	  , @partition_number             int
	  , @IndexName                    sysname
	  , @avg_fragmentation_in_percent float

SET @RebuildIndex = CURSOR FOR

select TableSchemaName, TableName, partition_number, IndexName, avg_fragmentation_in_percent
from [Core].[GetIndexFragmentation] (@SchemaName, @TableName, @DaysToConsider, @EndDateTime_UTC)
WHERE TableSchemaName =    @SchemaName
  AND TableName       LIKE @TableName
  AND avg_fragmentation_in_percent >= @FragmentationLimit;

DECLARE @StepId bigint
DECLARE @StepParameterValues NVARCHAR(max)

OPEN @RebuildIndex

FETCH NEXT FROM @RebuildIndex 
  INTO   @TableSchemaName              
	   , @SelectedTableName                    
	   , @partition_number             
	   , @IndexName                    
	   , @avg_fragmentation_in_percent 

DECLARE @SQLString nvarchar(max)

WHILE @@fetch_status = 0
  BEGIN

      -- Rebuild Index
	  SET @SQLString =  'ALTER INDEX   [' + @IndexName + '] ON [' + @TableSchemaName + '].[' + @SelectedTableName + '] '
      SET @SQLString += 'REBUILD Partition = ' + convert(varchar, @partition_number) + ' WITH (ONLINE=ON);'

      SET @StepParameterValues = @SQLString
	  EXEC [Logging].[StartStep] @TaskId, 'RebuildIndex', @StepParameterValues, @StepId =   @StepId output

print @SQLString

	  EXEC [Helper].[Conditional_sp_executesql_print] @SQLString

	  EXEC [Logging].[EndStep] @StepId, 'End', NULL

	  -- Update Statistics
	  SET @SQLString =  'UPDATE STATISTICS [' + @TableSchemaName + '].[' + @SelectedTableName + '] (' + @IndexName + ') '
      SET @SQLString += 'WITH RESAMPLE ON PARTITIONS(' + convert(varchar, @partition_number) + ');'

      SET @StepParameterValues = @SQLString

print @SQLString

	  EXEC [Logging].[StartStep] @TaskId, 'UPDATE STATISTICS', @StepParameterValues, @StepId =   @StepId output

	  EXEC [Helper].[Conditional_sp_executesql_print] @SQLString

	  EXEC [Logging].[EndStep] @StepId, 'End', NULL


      FETCH NEXT FROM @RebuildIndex 
		  INTO   @TableSchemaName              
			   , @SelectedTableName                    
			   , @partition_number             
			   , @IndexName                    
			   , @avg_fragmentation_in_percent 
  END

 CLOSE @RebuildIndex
 DEALLOCATE @RebuildIndex

 EXEC [Logging].[EndTask]  @TaskId, 'End', NULL

 SELECT 0 AS ReturnDataSet

END