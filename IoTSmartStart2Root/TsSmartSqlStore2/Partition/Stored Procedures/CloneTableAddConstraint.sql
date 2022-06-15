
CREATE PROCEDURE [Partition].[CloneTableAddConstraint]
(
   @TargetSchemaName       SYSNAME 
  ,@TargetTableName        SYSNAME
  ,@ConstraintNamePrefix   SYSNAME 
  ,@ConstraintDefinition   NVARCHAR(MAX) 
)
AS
BEGIN
  DECLARE @SQLString nvarchar(max)


  SET @SQLString = CONCAT('ALTER TABLE ',QUOTENAME(@TargetSchemaName), '.', QUOTENAME(@TargetTableName),'') + char(13)
  SET @SQLString = @SQLString + CONCAT(' ADD CONSTRAINT [', @ConstraintNamePrefix, '_', @TargetSchemaName, '_', @TargetTableName ,'] '
                                      , @ConstraintDefinition,';') + char(13)

  EXEC [Helper].[Conditional_sp_executesql_print] @SQLString
END