

CREATE PROCEDURE [Partition].[CreateSwitchTable]  @SchemaName           sysname
                                                ,@TableName            sysname
												,@CheckConstraintSQL   nvarchar(max)
												,@StorageLocation      nvarchar(max)
												
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @FullTableNameSQL         NVARCHAR(MAX)
         ,@DropExistingTableSQL     NVARCHAR(MAX)
		 ,@CreateTableSQL           NVARCHAR(MAX)
		 ,@CreateCCISQL             NVARCHAR(MAX)
         ,@CreateCCIPlusSQL         NVARCHAR(MAX)
		 ,@PKFKConstraints          NVARCHAR(MAX)
		 ,@PKFKConstraintsRequired  TINYINT 
		 ,@CCIRequired              TINYINT 

  -- The table MeasurementStore is using a cluster columnstore index but no foreignkey constraints
  -- The table Measurement is using no CCI but a Primary Key and a Foreign Key constraint
  IF CHARINDEX('MeasurementStore',@TableName) > 0
  BEGIN
    SET @CCIRequired              = 1
	SET @PKFKConstraintsRequired  = 0
  END
  ELSE
  BEGIN
    SET @CCIRequired              = 0
    SET @PKFKConstraintsRequired  = 1
  END 


  SET @FullTableNameSQL = CONCAT(QUOTENAME(@SchemaName),'.' , QUOTENAME(@TableName))

  SET @DropExistingTableSQL = CONCAT('IF OBJECT_ID(''', @FullTableNameSQL,''') IS NOT NULL
                                        DROP TABLE ', @FullTableNameSQL,';')

  -- If the table is organised as Clustered Index, then the switch table needs also a CI and also the fk references
  IF @PKFKConstraintsRequired = 1
    SET @PKFKConstraints = CONCAT('
      ,CONSTRAINT [PK_', @SchemaName, '_', @TableName ,'] PRIMARY KEY CLUSTERED ([SignalId] ASC, [Ts] DESC, [Ts_Day] DESC) WITH (DATA_COMPRESSION = PAGE ) ', @StorageLocation, '
      ,CONSTRAINT [FK_', @SchemaName, '_', @TableName ,'] FOREIGN KEY ([SignalId]) REFERENCES [Core].[Signal] ([SignalId]),')
  ELSE
   SET  @PKFKConstraints = ''

  SET @CreateCCISQL = CONCAT('CREATE CLUSTERED COLUMNSTORE INDEX [CCI_', @SchemaName, '_', @TableName ,'] ON ', @FullTableNameSQL)

  SET @CreateCCIPlusSQL = CONCAT(
    'CREATE NONCLUSTERED INDEX [NCIX_', @SchemaName, '_', @TableName ,'TsTs_DaySignalId]
         ON ', @FullTableNameSQL,'([Ts] ASC, [Ts_Day] ASC, [SignalId] ASC) WITH (DATA_COMPRESSION = PAGE)'
                                )
    
    

  SET @CreateTableSQL = CONCAT(
  'CREATE TABLE ', @FullTableNameSQL,' (
    [Ts]               DATETIME2 (3) NOT NULL,
    [Ts_Day]           DATETIME2 (0) NOT NULL,
    [SignalId]         INT           NOT NULL,
    [MeasurementValue] REAL            NULL,
    [MeasurementText]  NVARCHAR (4000) NULL,
    [CreatedAt]        DATETIME2 (3)   NULL
	,CONSTRAINT [CK_', @SchemaName, '_', @TableName ,'] ', @CheckConstraintSQL, '
	',@PKFKConstraints,'
  ) ', @StorageLocation, ';'
  );

  exec sp_executesql  @DropExistingTableSQL
  exec sp_executesql  @CreateTableSQL
  --print @CreateTableSQL


  IF @CCIRequired=1
  BEGIN
    EXEC sp_executesql  @CreateCCISQL
    EXEC sp_executesql  @CreateCCIPlusSQL
    --print @CreateCCISQL
  END
  

END