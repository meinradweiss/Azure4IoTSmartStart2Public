/*
 Pre-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be executed before the build script.	
 Use SQLCMD syntax to include a file in the pre-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the pre-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

-- 20211209 Enable Incremental Statistics

  -- Drop all autocreated statistics to enable incremental updates on partitioned tables
  -- https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql-set-options?view=sql-server-ver15
  -- https://docs.microsoft.com/en-us/sql/relational-databases/statistics/statistics?view=sql-server-ver15
  --
  -- This is necessary to support INCREMENTAL = ON
  
  DECLARE @SqlCommand NVARCHAR(MAX)
  
  DECLARE NonIncrementalStatistics CURSOR FOR 
  SELECT  'DROP STATISTICS ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(OBJECT_NAME(stats.object_id)) + '.' + QUOTENAME(stats.name)  AS SqlCommand
  from sys.stats
  INNER JOIN sys.objects ON stats.object_id = objects.object_id
  WHERE auto_created =1
    AND SCHEMA_NAME(schema_id) = 'Core'
    AND is_incremental = 0;
  
  OPEN NonIncrementalStatistics  
    
  FETCH NEXT FROM NonIncrementalStatistics   
  INTO @SqlCommand
  
    
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
  
    EXECUTE sp_executesql @SqlCommand
  
    FETCH NEXT FROM NonIncrementalStatistics   
    INTO @SqlCommand
  
  END   

  CLOSE NonIncrementalStatistics;  
  DEALLOCATE NonIncrementalStatistics;

