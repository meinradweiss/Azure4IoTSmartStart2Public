/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
/*
DECLARE @RC                         AS INT
      , @startDate                  AS DATE
      , @firstDayOfMonthOfStartDate AS DATE
      , @dayAheadNumber             AS INT

SELECT @startDate      = DATEADD(DAY, -65, GETUTCDATE()) -- Your desired start date (earliest telemetry ts)
      ,@dayAheadNumber = 35
      ,@RC             = 0

    

-- Create Partitions for Days and Months
EXECUTE @RC = [Partition].[MaintainPartitionBorders] @startDate, @dayAheadNumber;
*/