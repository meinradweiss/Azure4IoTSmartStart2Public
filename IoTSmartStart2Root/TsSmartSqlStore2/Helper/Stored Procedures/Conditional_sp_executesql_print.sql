


CREATE PROCEDURE [Helper].[Conditional_sp_executesql_print](@SQLString NVARCHAR(MAX))
AS
BEGIN
  IF [Config].[GetSystemConfigDebugMode]() = 'None'
  BEGIN
    EXEC sp_executesql @SQLString
  END
  ELSE
    IF [Config].[GetSystemConfigDebugMode]() = 'Verbose'
    BEGIN
      PRINT @SQLString
      EXEC sp_executesql @SQLString
    END
	ELSE 
      PRINT 'DebugMode: Valid values are None/Verbose'


END