
CREATE PROCEDURE [Partition].[CloneFkConstraints]
(
   @SourceSchemaName       SYSNAME 
  ,@SourceTableName        SYSNAME 
  ,@TargetSchemaName       SYSNAME 
  ,@TargetTableName        SYSNAME 
)
AS
BEGIN
  -- Source: https://www.mssqltips.com/sqlservertip/3443/script-all-primary-keys-unique-constraints-and-foreign-keys-in-a-sql-server-database-using-tsql/


  --- SCRIPT TO GENERATE THE CREATION SCRIPT OF ALL FOREIGN KEY CONSTRAINTS
  declare @ForeignKeyID          int
  declare @ForeignKeyName        varchar(4000)
  declare @ParentTableName       varchar(4000)
  declare @ParentColumn          varchar(4000)
  declare @ReferencedTable       varchar(4000)
  declare @ReferencedColumn      varchar(4000)
  declare @StrParentColumn       varchar(max)
  declare @StrReferencedColumn   varchar(max)
  declare @ParentTableSchema     varchar(4000)
  declare @ReferencedTableSchema varchar(4000)
  declare @TSQLCreationFK        varchar(max)
  --Written by Percy Reyes www.percyreyes.com
  declare CursorFK cursor 
  for 
      select fk.object_id
      from sys.tables t 
        inner join sys.foreign_keys fk
        on t.object_id = fk.parent_object_id
      where  schema_name(t.schema_id) = @SourceSchemaName 
       and t.name                     = @SourceTableName



  open CursorFK
  fetch next from CursorFK into @ForeignKeyID
  while (@@FETCH_STATUS=0)
  begin
   set @StrParentColumn=''
   set @StrReferencedColumn=''
   declare CursorFKDetails cursor for
    select  fk.name ForeignKeyName, schema_name(t1.schema_id) ParentTableSchema,
    object_name(fkc.parent_object_id) ParentTable, c1.name ParentColumn,schema_name(t2.schema_id) ReferencedTableSchema,
     object_name(fkc.referenced_object_id) ReferencedTable,c2.name ReferencedColumn
    from --sys.tables t inner join 
    sys.foreign_keys fk 
    inner join sys.foreign_key_columns fkc on fk.object_id=fkc.constraint_object_id
    inner join sys.columns c1 on c1.object_id=fkc.parent_object_id and c1.column_id=fkc.parent_column_id 
    inner join sys.columns c2 on c2.object_id=fkc.referenced_object_id and c2.column_id=fkc.referenced_column_id 
    inner join sys.tables t1 on t1.object_id=fkc.parent_object_id 
    inner join sys.tables t2 on t2.object_id=fkc.referenced_object_id 
    where fk.object_id=@ForeignKeyID
   open CursorFKDetails
   fetch next from CursorFKDetails into  @ForeignKeyName, @ParentTableSchema, @ParentTableName, @ParentColumn, @ReferencedTableSchema, @ReferencedTable, @ReferencedColumn
   while (@@FETCH_STATUS=0)
   begin    
    set @StrParentColumn=@StrParentColumn + ', ' + quotename(@ParentColumn)
    set @StrReferencedColumn=@StrReferencedColumn + ', ' + quotename(@ReferencedColumn)
    
       fetch next from CursorFKDetails into  @ForeignKeyName, @ParentTableSchema, @ParentTableName, @ParentColumn, @ReferencedTableSchema, @ReferencedTable, @ReferencedColumn
   end
   close CursorFKDetails
   deallocate CursorFKDetails
  
   set @ForeignKeyName = replace(@ForeignKeyName, @SourceTableName, @TargetTableName)

   set @StrParentColumn=substring(@StrParentColumn,2,len(@StrParentColumn)-1)
   set @StrReferencedColumn=substring(@StrReferencedColumn,2,len(@StrReferencedColumn)-1)
   set @TSQLCreationFK='ALTER TABLE '+quotename(@TargetSchemaName)+'.'+quotename(@TargetTableName)+' WITH CHECK ADD CONSTRAINT '+quotename(@ForeignKeyName)
   + ' FOREIGN KEY('+ltrim(@StrParentColumn)+') '+ char(13) +'REFERENCES '+quotename(@ReferencedTableSchema)+'.'+quotename(@ReferencedTable)+' ('+ltrim(@StrReferencedColumn)+') ' + char(13)+';'
   
   EXEC [Helper].[Conditional_sp_executesql_print] @TSQLCreationFK
  
  fetch next from CursorFK into @ForeignKeyID 
  end
  close CursorFK
  deallocate CursorFK
END