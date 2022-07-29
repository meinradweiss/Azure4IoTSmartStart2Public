

CREATE FUNCTION [Core].[GetIndexFragmentation] 
  (  @DaysToConsider   INT          = 1
    ,@EndDateTime_UTC  DATETIME2(3) = NULL
  )
RETURNS TABLE
AS 
RETURN 

WITH AffectedIndexes
AS
(

  SELECT OBJECT_NAME(p.object_id)        AS TableName ,
         p.object_id                     AS TableObject_id ,
         p.partition_number,
         i.index_id,
         i.name                          AS IndexName ,
         p.index_id                      AS IndexID ,
         ds.name                         AS PartitionScheme ,
         p.partition_number              AS PartitionNumber ,
         prv_right.value                 AS UpperBoundaryValue ,
         p.rows                          AS Rows
  FROM sys.partitions AS p
   INNER JOIN sys.indexes AS i 
      ON i.object_id = p.object_id
     AND i.index_id = p.index_id
   INNER JOIN sys.data_spaces AS ds 
      ON ds.data_space_id = i.data_space_id
   INNER JOIN sys.partition_schemes AS ps 
      ON ps.data_space_id = ds.data_space_id
   INNER JOIN sys.partition_functions AS pf 
      ON pf.function_id = ps.function_id
   INNER JOIN sys.destination_data_spaces AS dds 
      ON dds.partition_scheme_id = ps.data_space_id
   AND dds.destination_id = p.partition_number
   INNER JOIN sys.filegroups AS fg 
      ON fg.data_space_id = dds.data_space_id
   LEFT OUTER JOIN sys.partition_range_values AS prv_right 
     ON ps.function_id = prv_right.function_id
     AND prv_right.boundary_id = p.partition_number
  WHERE prv_right.value IS NOT NULL
    AND prv_right.value  > convert(int, convert(varchar, dateadd(day,(ABS(@DaysToConsider) * -1), COALESCE(@EndDateTime_UTC, GETUTCDATE())), 112))
    AND prv_right.value <= convert(int, convert(varchar,                                     COALESCE(@EndDateTime_UTC, GETUTCDATE()),  112))
)
, FragementationInfo
AS
(
  SELECT AffectedIndexes.*
       , FragmentedIndex.index_type_desc          
       , FragmentedIndex.avg_fragmentation_in_percent

  FROM AffectedIndexes
  CROSS APPLY sys.dm_db_index_physical_stats (DB_ID(), TableObject_id, index_id,partition_number, NULL) AS FragmentedIndex
)
SELECT DISTINCT SCHEMA_NAME(objects.schema_id)  AS TableSchemaName
               , FragementationInfo.TableName
			   , FragementationInfo.partition_number
			   , IndexName
			   , index_type_desc
			   , avg_fragmentation_in_percent 
			   --,*
FROM FragementationInfo
INNER JOIN sys.objects
  ON object_id = FragementationInfo.TableObject_id