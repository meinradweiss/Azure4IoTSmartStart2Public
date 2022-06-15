CREATE PROCEDURE [Partition].[CheckNonTrustedConstraints]
AS
BEGIN

  DECLARE @SQLString nvarchar(max)

  DECLARE NonTrustedConstraint CURSOR FOR
  SELECT 
    CONCAT('ALTER TABLE ',QUOTENAME(SCHEMA_NAME(schema_id)),'.',QUOTENAME(OBJECT_NAME(parent_object_id)),' WITH CHECK CHECK CONSTRAINT ', QUOTENAME(name))
  FROM sys.foreign_keys
  WHERE SCHEMA_NAME(schema_id) = 'CORE'
    AND is_disabled    = 0
    AND is_not_trusted = 1;


  OPEN NonTrustedConstraint
  FETCH NEXT FROM NonTrustedConstraint INTO  @SQLString  

  WHILE (@@FETCH_STATUS=0)
  BEGIN
    EXEC [Helper].[Conditional_sp_executesql_print] @SQLString

    FETCH NEXT FROM NonTrustedConstraint INTO  @SQLString  
  								   
  END

  CLOSE NonTrustedConstraint
  DEALLOCATE NonTrustedConstraint

END