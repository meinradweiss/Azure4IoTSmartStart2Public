
CREATE PROCEDURE [Partition].[ClonePkAndUcConstraints]
(
   @SourceSchemaName       SYSNAME 
  ,@SourceTableName        SYSNAME 
  ,@TargetSchemaName       SYSNAME 
  ,@TargetTableName        SYSNAME 
  ,@ForceStorageLocation   SYSNAME = NULL

)
AS
BEGIN
  -- Source: https://www.mssqltips.com/sqlservertip/3443/script-all-primary-keys-unique-constraints-and-foreign-keys-in-a-sql-server-database-using-tsql/


  declare @IndexName varchar(256)
  declare @ColumnName varchar(100)
  declare @is_unique_constraint varchar(100)
  declare @IndexTypeDesc sysname
  declare @FileGroupName sysname
  declare @is_disabled varchar(100)
  declare @IndexOptions varchar(max)
  declare @IndexColumnId int
  declare @IsDescendingKey int 
  declare @IsIncludedColumn int
  declare @TSQLScripCreationIndex Nvarchar(max)
  declare @TSQLScripDisableIndex Nvarchar(max)
  declare @is_primary_key varchar(100)
  
  declare CursorIndex cursor for
   select schema_name(t.schema_id) [schema_name], t.name, ix.name,
   case when ix.is_unique_constraint = 1 then ' UNIQUE ' else '' END 
      ,case when ix.is_primary_key = 1 then ' PRIMARY KEY ' else '' END 
   , ix.type_desc,
    case when ix.is_padded=1 then 'PAD_INDEX = ON ' else 'PAD_INDEX = OFF ' end
   + case when ix.allow_page_locks=1 then ', ALLOW_PAGE_LOCKS = ON ' else ', ALLOW_PAGE_LOCKS = OFF ' end
   + case when ix.allow_row_locks=1 then  ', ALLOW_ROW_LOCKS = ON ' else ', ALLOW_ROW_LOCKS = OFF ' end
   + case when INDEXPROPERTY(t.object_id, ix.name, 'IsStatistics') = 1 then ', STATISTICS_NORECOMPUTE = ON ' else ', STATISTICS_NORECOMPUTE = OFF ' end
   + case when ix.ignore_dup_key=1 then ', IGNORE_DUP_KEY = ON ' else ', IGNORE_DUP_KEY = OFF ' end
   + CONCAT(', DATA_COMPRESSION = ',  p.data_compression_desc)
   + case when ix.fill_factor <> 0 then ', FILLFACTOR = ' + CONVERT(VARCHAR, ix.fill_factor) else '' end
   
   AS IndexOptions
   ,case when ix.data_space_id <= 255 THEN QUOTENAME(FILEGROUP_NAME(ix.data_space_id)) 
                                      ELSE (SELECT CONCAT (QUOTENAME(name), '([Ts_Day])')
                                            FROM sys.partition_schemes
                                            WHERE partition_schemes.data_space_id = ix.data_space_id)
          end as FileGroupName
   from sys.tables t 
   inner join sys.indexes ix on t.object_id=ix.object_id

   		inner join sys.partitions p
		  on t.object_id = p.object_id
		  and ix.index_id = p.index_id
		inner join (select object_id, index_id, max(partition_id) as MaxPartition_id
  	                from sys.partitions
        	        group by object_id, index_id) as pMax
	           on  p.object_id = pMax.object_id
	           and p.index_id = pMax.index_id
			   and p.partition_id = MaxPartition_id

   where ix.type>0 and  (ix.is_primary_key=1 or ix.is_unique_constraint=1) 
     and schema_name(t.schema_id) = @SourceSchemaName 
	 and t.name                   = @SourceTableName
     and t.is_ms_shipped=0 and t.name<>'sysdiagrams'
   order by schema_name(t.schema_id), t.name, ix.name

  open CursorIndex
  fetch next from CursorIndex 
    into  @SourceSchemaName, @SourceTableName, @IndexName, @is_unique_constraint, @is_primary_key, @IndexTypeDesc, @IndexOptions, @FileGroupName

  while (@@fetch_status=0)
  begin
   declare @IndexColumns varchar(max)
   declare @IncludedColumns varchar(max)
   set @IndexColumns=''
   set @IncludedColumns=''
   declare CursorIndexColumn cursor for 
   select col.name, ixc.is_descending_key, ixc.is_included_column
   from sys.tables tb 
   inner join sys.indexes ix on tb.object_id=ix.object_id
   inner join sys.index_columns ixc on ix.object_id=ixc.object_id and ix.index_id= ixc.index_id
   inner join sys.columns col on ixc.object_id =col.object_id  and ixc.column_id=col.column_id
   where ix.type>0 and (ix.is_primary_key=1 or ix.is_unique_constraint=1)
   and schema_name(tb.schema_id)=@SourceSchemaName and tb.name=@SourceTableName and ix.name=@IndexName
   order by ixc.key_ordinal
   open CursorIndexColumn 
   fetch next from CursorIndexColumn into  @ColumnName, @IsDescendingKey, @IsIncludedColumn
   while (@@fetch_status=0)
   begin
    if @IsIncludedColumn=0 
      set @IndexColumns=@IndexColumns + QUOTENAME(@ColumnName)  + case when @IsDescendingKey=1  then ' DESC, ' else  ' ASC, ' end
    else 
     set @IncludedColumns=@IncludedColumns  + QUOTENAME(@ColumnName)  +', ' 
       
    fetch next from CursorIndexColumn into @ColumnName, @IsDescendingKey, @IsIncludedColumn
   end
   close CursorIndexColumn
   deallocate CursorIndexColumn
   set @IndexColumns = substring(@IndexColumns, 1, len(@IndexColumns)-1)
   set @IncludedColumns = case when len(@IncludedColumns) >0 then substring(@IncludedColumns, 1, len(@IncludedColumns)-1) else '' end
  --  EXEC [Helper].[Conditional_sp_executesql_print] @IndexColumns
  --  EXEC [Helper].[Conditional_sp_executesql_print] @IncludedColumns
  
  SET @IndexName     = REPLACE(@IndexName, @SourceTableName, @TargetTableName )
  SET @FileGroupName = COALESCE(@ForceStorageLocation, @FileGroupName)

  set @TSQLScripCreationIndex =''
  set @TSQLScripDisableIndex =''
  set  @TSQLScripCreationIndex='ALTER TABLE '+  QUOTENAME(@TargetSchemaName) +'.'+ QUOTENAME(@TargetTableName)+ ' ADD CONSTRAINT ' +  QUOTENAME(@IndexName) + @is_unique_constraint + @is_primary_key + @IndexTypeDesc +  '('+@IndexColumns+') '+ 
   case when len(@IncludedColumns)>0 then CHAR(13) +'INCLUDE (' + @IncludedColumns+ ')' else '' end + CHAR(13)+'WITH (' + @IndexOptions+ ') ON ' + @FileGroupName + ';'  
  
  EXEC [Helper].[Conditional_sp_executesql_print] @TSQLScripCreationIndex
  EXEC [Helper].[Conditional_sp_executesql_print] @TSQLScripDisableIndex
  
  fetch next from CursorIndex into  @SourceSchemaName, @SourceTableName, @IndexName, @is_unique_constraint, @is_primary_key, @IndexTypeDesc, @IndexOptions, @FileGroupName
  
  end
  close CursorIndex
  deallocate CursorIndex

END