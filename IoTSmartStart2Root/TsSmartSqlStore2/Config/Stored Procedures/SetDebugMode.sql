

CREATE PROCEDURE [Config].[SetDebugMode] (@Mode VARCHAR(25))
AS
BEGIN

   INSERT INTO [Config].[SystemConfig]([SystemConfigName], [SystemConfigValue])
   SELECT 'DebugMode', @Mode
   --FROM [Config].[SystemConfig]
   WHERE NOT EXISTS (SELECT 'X' FROM [Config].[SystemConfig] WHERE [SystemConfigName] = 'DebugMode');

   UPDATE X
     SET [SystemConfigValue] = @Mode
   FROM [Config].[SystemConfig] AS X
   WHERE X.SystemConfigName = 'DebugMode';

END