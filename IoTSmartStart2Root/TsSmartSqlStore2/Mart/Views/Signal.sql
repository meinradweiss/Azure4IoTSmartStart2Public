CREATE VIEW [Mart].[Signal]
AS
SELECT       [SignalId]
            ,[SignalName]
            ,[DeviceId] 
            ,[Measurand]
            ,[UpdateLatestMeasurement] 
FROM [Core].[Signal]