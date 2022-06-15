

CREATE PROCEDURE [Helper].[Conditional_print](@SQLString NVARCHAR(MAX))
AS
BEGIN

    IF [Config].[GetSystemConfigDebugMode]() = 'Verbose'
    BEGIN
      PRINT @SQLString
    END
	ELSE 
      IF [Config].[GetSystemConfigDebugMode]() <> 'None'
      BEGIN
	    PRINT 'DebugMode: Valid values are None/Verbose'
      END


END