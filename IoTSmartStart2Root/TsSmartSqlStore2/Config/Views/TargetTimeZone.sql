CREATE VIEW [Config].[TargetTimeZone]
AS

  SELECT COALESCE(CONVERT(NVARCHAR, [SystemConfig].[SystemConfigValue])
                        ,'Central European Standard Time')                AS TargetTimeZone
  FROM  [Config].[SystemConfig] 
  WHERE [SystemConfig].[SystemConfigName] = 'LocalTimezone'