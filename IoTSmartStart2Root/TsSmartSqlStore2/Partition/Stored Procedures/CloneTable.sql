
CREATE PROCEDURE [Partition].[CloneTable](
   @SourceSchemaName       SYSNAME 
  ,@SourceTableName        SYSNAME 
  ,@TargetSchemaName       SYSNAME 
  ,@TargetTableName        SYSNAME 
  ,@ForceStorageLocation   SYSNAME = NULL
  ,@ConstraintNamePrefix   SYSNAME 
  ,@ConstraintDefinition   NVARCHAR(MAX) 
  )

AS

BEGIN

  EXEC [Partition].[CheckNonTrustedConstraints]

  EXEC [Partition].[CloneTableStructure]      @SourceSchemaName  = @SourceSchemaName, @SourceTableName   = @SourceTableName
  										     ,@TargetSchemaName  = @TargetSchemaName, @TargetTableName   = @TargetTableName 
  										     ,@ForceStorageLocation = @ForceStorageLocation
  
  
  EXEC [Partition].[CloneRegularIndexes]      @SourceSchemaName  = @SourceSchemaName, @SourceTableName   = @SourceTableName
                                             ,@TargetSchemaName  = @TargetSchemaName, @TargetTableName   = @TargetTableName 
  										     ,@ForceStorageLocation = @ForceStorageLocation
  
  EXEC [Partition].[ClonePkAndUcConstraints]  @SourceSchemaName  = @SourceSchemaName, @SourceTableName   = @SourceTableName
  										     ,@TargetSchemaName  = @TargetSchemaName, @TargetTableName   = @TargetTableName
  										     ,@ForceStorageLocation = @ForceStorageLocation
  
  EXEC [Partition].[CloneFkConstraints]       @SourceSchemaName  = @SourceSchemaName, @SourceTableName   = @SourceTableName
  										     ,@TargetSchemaName  = @TargetSchemaName, @TargetTableName   = @TargetTableName

  EXEC [Partition].[CloneTableAddConstraint]  @TargetSchemaName     = @TargetSchemaName,     @TargetTableName          = @TargetTableName
                                             ,@ConstraintNamePrefix = @ConstraintNamePrefix, @ConstraintDefinition     = @ConstraintDefinition
END