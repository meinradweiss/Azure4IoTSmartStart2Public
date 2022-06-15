CREATE VIEW [Partition].[TablePartitionFunction]
AS

  SELECT DISTINCT 
         SCHEMA_NAME(t.schema_id) AS SchemaName
	   , t.name                   AS TableName
	   , f.name                   AS PartitionFunctionName   
  FROM sys.tables AS t  
  JOIN sys.indexes AS i  
      ON t.object_id = i.object_id  
  JOIN sys.partitions AS p
      ON i.object_id = p.object_id AND i.index_id = p.index_id   
  JOIN  sys.partition_schemes AS s   
      ON i.data_space_id = s.data_space_id  
  JOIN sys.partition_functions AS f   
      ON s.function_id = f.function_id