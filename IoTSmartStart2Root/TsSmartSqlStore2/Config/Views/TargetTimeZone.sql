CREATE VIEW [Config].[TargetTimeZone]
AS


  SELECT COALESCE((SELECT CONVERT(NVARCHAR, [SystemConfigValue]) FROM  [Config].[SystemConfig] WHERE [SystemConfig].[SystemConfigName] = 'LocalTimezone')
                        ,'Central European Standard Time')                AS TargetTimeZone