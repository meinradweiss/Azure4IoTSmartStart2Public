
CREATE FUNCTION [Config].[GetSystemConfigDebugMode]()
RETURNS VARCHAR(256)
AS
BEGIN
  RETURN
    (SELECT ISNULL((SELECT CONVERT(VARCHAR, [SystemConfigValue]) 
                   FROM [Config].[SystemConfig] 
	      	       WHERE [SystemConfigName]='DebugMode'),'None') AS [SystemConfigValue])
  END