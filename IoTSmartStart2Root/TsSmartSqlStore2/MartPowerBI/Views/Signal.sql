CREATE VIEW [MartPowerBI].[Signal]
AS
SELECT       [SignalId]
            ,[SignalName]
            ,[DeviceId] 
            ,[Measurand]
            ,[UpdateLatestMeasurement] 
FROM [Core].[Signal]