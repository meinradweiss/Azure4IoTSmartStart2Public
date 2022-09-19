CREATE VIEW [Partition].[ListIndexesWithSTATISTICS_INCREMENTAL_OFF]
AS

-- Source: https://www.mssqltips.com/sqlservertip/5170/build-a-robust-incremental-sql-server-update-statistics-procedure/

  SELECT [Table]= OBJECT_SCHEMA_NAME(i.object_id)+'.'+ OBJECT_NAME(i.OBJECT_ID)
       , s.name, s.is_incremental
       , Fix_SQL = 'alter index ' + quotename(s.name, '[]') + 
                   ' on [' + OBJECT_SCHEMA_NAME(i.object_id) + '].[' + object_name(i.object_id) + 
                   '] rebuild with (STATISTICS_INCREMENTAL  = ON)'
  FROM sys.stats s
  INNER JOIN sys.indexes i 
    ON i.name = s.name
   AND i.object_id = s.object_id
  INNER JOIN sys.partition_schemes p 
    ON i.data_space_id = p.data_space_id 
  WHERE NOT EXISTS (SELECT TOP 1 'x'        -- Exclude coulmnstore indexes
                    FROM sys.indexes ai 
					WHERE  ai.type_desc IN ('CLUSTERED COLUMNSTORE', 'NONCLUSTERED COLUMNSTORE') 
					  AND ai.object_id = i.object_id)
     AND is_incremental = 0
  ;