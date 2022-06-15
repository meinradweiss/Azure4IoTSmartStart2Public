
CREATE PROCEDURE [Partition].[CloneTableStructure]
(
   @SourceSchemaName       SYSNAME 
  ,@SourceTableName        SYSNAME 
  ,@TargetSchemaName       SYSNAME 
  ,@TargetTableName        SYSNAME
  ,@ForceStorageLocation   SYSNAME = NULL
)
AS
BEGIN
  DECLARE @SQLString nvarchar(max)

  DECLARE @FileGroupName     NVARCHAR(MAX)
         ,@ColumnSequence    INT
		 ,@ColumnDefinition  NVARCHAR(MAX)

  SELECT @FileGroupName = case when ix.data_space_id <= 255 THEN QUOTENAME(FILEGROUP_NAME(ix.data_space_id))
                                      ELSE (SELECT CONCAT (QUOTENAME(name), '([Ts_Day])')
                                            FROM sys.partition_schemes
                                            WHERE partition_schemes.data_space_id = ix.data_space_id)
          END 
  FROM sys.tables tb
       inner join sys.indexes ix 
	    on tb.object_id=ix.object_id
  WHERE tb.schema_id = schema_id(@SourceSchemaName)
    AND tb.name      = @SourceTableName
	AND ix.index_id = 1

  DECLARE ColumnIndex CURSOR FOR

  SELECT ROW_NUMBER() OVER (PARTITION BY tb.object_id ORDER BY tb.object_id, col.column_id) AS ColumnSequence
          , QUOTENAME(col.name) + ' '
          + COALESCE(
              'AS ' + cmp.definition + CASE ISNULL(cmp.is_persisted, 0) WHEN 1 THEN ' PERSISTED ' ELSE '' END,
              CASE
                WHEN col.system_type_id != col.user_type_id THEN QUOTENAME(usr_tp.schema_name) + '.' + QUOTENAME(usr_tp.name)
                ELSE
                  QUOTENAME(sys_tp.name) +
                  CASE
                    WHEN sys_tp.name IN ('char', 'varchar', 'binary', 'varbinary') THEN '(' + CONVERT(VARCHAR, CASE col.max_length WHEN -1 THEN 'max' ELSE CAST(col.max_length AS varchar(10)) END) + ')'
                    WHEN sys_tp.name IN ('nchar', 'nvarchar') THEN '(' + CONVERT(VARCHAR, CASE col.max_length WHEN -1 THEN 'max' ELSE CAST(col.max_length/2 AS varchar(10)) END) + ')'
                    WHEN sys_tp.name IN ('decimal', 'numeric') THEN '(' + CAST(col.precision AS VARCHAR) + ',' + CAST(col.scale AS VARCHAR) + ')'
                    WHEN sys_tp.name IN ('datetime2') THEN '(' + CAST(col.scale AS VARCHAR) + ')'
                    ELSE ''
                  END
              END
              )
          + CASE col.is_nullable
              WHEN 0 THEN ' NOT NULL'
              ELSE CASE WHEN cmp.definition IS NULL THEN ' NULL' ELSE ' ' END
            END AS ColumnDefinition
         FROM sys.tables tb
         JOIN sys.schemas sch
           ON sch.schema_id = tb.schema_id
         JOIN sys.columns col
           ON col.object_id = tb.object_id
         JOIN sys.types sys_tp
           ON col.system_type_id = sys_tp.system_type_id
          AND col.system_type_id = sys_tp.user_type_id
         LEFT JOIN
              (
              SELECT tp.*, sch.name AS [schema_name]
              FROM sys.types tp
              JOIN sys.schemas sch
              ON tp.schema_id = sch.schema_id
              ) usr_tp
           ON col.system_type_id = usr_tp.system_type_id
          AND col.user_type_id = usr_tp.user_type_id
         LEFT JOIN sys.computed_columns cmp
           ON cmp.object_id = tb.object_id
          AND cmp.column_id = col.column_id
  
  		WHERE tb.schema_id = schema_id(@SourceSchemaName)
  		  AND tb.name      = @SourceTableName

  OPEN ColumnIndex
  FETCH NEXT FROM ColumnIndex INTO  @ColumnSequence  
  								  , @ColumnDefinition


  SET @FileGroupName = COALESCE(@ForceStorageLocation, @FileGroupName)

  SET @SQLString = CONCAT('CREATE TABLE ',QUOTENAME(@TargetSchemaName), '.', QUOTENAME(@TargetTableName),'(') + char(13)

  WHILE (@@FETCH_STATUS=0)
  BEGIN
    SET @SQLString = @SQLString + CASE WHEN @ColumnSequence > 1 THEN '  ,' ELSE '   ' END  + @ColumnDefinition + char(13)

    FETCH NEXT FROM ColumnIndex INTO  @ColumnSequence  
  								    , @ColumnDefinition
  END
  SET @SQLString = @SQLString + ')'
  SET @SQLString = @SQLString + ' ON ' + @FileGroupName +';'
  CLOSE ColumnIndex
  DEALLOCATE ColumnIndex

  EXEC [Helper].[Conditional_sp_executesql_print] @SQLString
END