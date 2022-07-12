CREATE VIEW [Mart].[TsDay]
AS

SELECT *
FROM [Core].[TsDay]
WHERE Ts_Date <= GETDATE()