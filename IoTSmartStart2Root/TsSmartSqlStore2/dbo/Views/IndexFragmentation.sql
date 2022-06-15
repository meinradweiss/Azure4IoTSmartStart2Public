CREATE VIEW [dbo].[IndexFragmentation]
AS


WITH IndexAndPartitonBoundary
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
    AND prv_right.value  > convert(date, dateadd(day,-90, getdate()))
    AND prv_right.value <= convert(date,                   getdate())
)
, FragementationInfo
AS
(
select schema_name(o.schema_id)                   AS TableSchemaName
     , object_name(FragmentedIndex.object_id)     AS TableName
       , FragmentedIndex.object_id                AS TableObject_Id
       , FragmentedIndex.index_id
	   , FragmentedIndex.index_type_desc          
       , FragmentedIndex.partition_number
       , FragmentedIndex.avg_fragmentation_in_percent
from  sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL,0, NULL) as FragmentedIndex
  inner join sys.objects AS o
    on  FragmentedIndex.object_id  = o.object_id
  inner join sys.indexes AS i
    on  FragmentedIndex.object_id  = i.object_id
       and FragmentedIndex.index_id = i.index_id
)
select distinct FragementationInfo.TableSchemaName, FragementationInfo.TableName, FragementationInfo.partition_number, IndexName, index_type_desc, avg_fragmentation_in_percent --,*
from FragementationInfo
  inner join IndexAndPartitonBoundary
    on  FragementationInfo.TableObject_Id = IndexAndPartitonBoundary.TableObject_Id
    and FragementationInfo.partition_number = IndexAndPartitonBoundary.partition_number
    and FragementationInfo.index_id = IndexAndPartitonBoundary.index_id