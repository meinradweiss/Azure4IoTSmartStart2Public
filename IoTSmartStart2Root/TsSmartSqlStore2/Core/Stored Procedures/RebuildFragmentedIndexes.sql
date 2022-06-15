CREATE PROCEDURE [Core].[RebuildFragmentedIndexes] (@FragmentationLimit float = 80.0)
AS
BEGIN


SET NOCOUNT ON

DECLARE @RebuildIndex CURSOR;

DECLARE @TaskId BIGINT
DECLARE @TaskParameterValues NVARCHAR(max)
SET @TaskParameterValues = '@FragmentationLimit = ' + convert(varchar, @FragmentationLimit) 
EXEC [Logging].[StartTask]  'RebuildFragmentedIndexes', @TaskParameterValues, @TaskId =   @TaskId output

DECLARE @TableSchemaName              sysname
	  , @TableName                    sysname
	  , @partition_number             int
	  , @IndexName                    sysname
	  , @avg_fragmentation_in_percent float

SET @RebuildIndex = CURSOR FOR

select TableSchemaName, TableName, partition_number, IndexName, avg_fragmentation_in_percent
from [dbo].[IndexFragmentation]
WHERE  TableSchemaName = 'Core'
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
      SET @SQLString += 'REBUILD Partition = ' + convert(varchar, @partition_number) + ' WITH(ONLINE=ON);'

      SET @StepParameterValues = @SQLString
	  EXEC [Logging].[StartStep] @TaskId, 'RebuildIndex', @StepParameterValues, @StepId =   @StepId output

      EXEC sp_executesql @statement = @SQLString ;
	  --PRINT @SQLString
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


END