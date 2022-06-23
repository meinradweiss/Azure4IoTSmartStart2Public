
CREATE VIEW  [Ingest].[Measurement]
AS
  -- Ingest Facade

  SELECT
	 [Ts] 
	,[SignalId] 
	,[MeasurementValue] 
	,[MeasurementText] 
  FROM [Core].[Measurement]
GO

CREATE TRIGGER [Ingest].[IngestMeasurementInsteadOfInsertTrigger]
ON [Ingest].[Measurement]
  INSTEAD OF INSERT
AS
  SET NOCOUNT ON;
  -- This is new

  -- Store measurements that already exist in the duplicate key table.
  INSERT INTO [Core].[MeasurementDuplicateKey] 
  (
        [Ts]
       ,[Ts_Day]     
       ,[SignalId]
       ,[MeasurementValue]
       ,[MeasurementText]
       ,[CreatedAt]
  )
  SELECT 
        i.[Ts]               
       ,CONVERT(DATE, i.[Ts])           AS Ts_Day      -- Calculate partition Key, Date type will be converted to DateTime2(0)
       ,CONVERT(INT,    i.[SignalId])
       ,i.[MeasurementValue] 
       ,i.[MeasurementText]
        ,GETUTCDATE()
  FROM INSERTED as i 
    INNER JOIN [Core].[AllMeasurement] AS m
       ON  i.[SignalId]   = m.[SignalId] 
         AND i.[Ts]       = m.[Ts] 
         AND m.[Ts_Day]   = CONVERT(DATETIME2(0), CONVERT(DATE, i.[Ts]));  -- Enable partition elimination

  -- Insert duplicate records if the happen in one batch of data
  INSERT INTO [Core].[MeasurementDuplicateKey] 
  (
        [Ts]
       ,[Ts_Day]     
       ,[SignalId]
       ,[MeasurementValue]
       ,[MeasurementText]
       ,[CreatedAt]
  )
  SELECT [INSERTED].[Ts]
        ,CONVERT(DATE, [INSERTED].[Ts])           AS [Ts_Day]      -- Calculate partition Key, Date type will be converted to DateTime2(0)
        ,CONVERT(INT,  [INSERTED].[SignalId])     AS [SignalId]
        ,[MeasurementValue]
        ,[MeasurementText]
        ,GETUTCDATE()
  FROM [INSERTED]
    INNER JOIN (SELECT i.[Ts]               
                         ,i.[SignalId]
                         ,COUNT(*)     as c
                FROM INSERTED as i 
                GROUP BY i.[Ts]               
                           ,i.[SignalId]
                   HAVING COUNT(*) > 1
       ) AS DUPLICATE_ROWS
       ON  [INSERTED].[Ts]       = [DUPLICATE_ROWS].[Ts]
       AND [INSERTED].[SignalId] = [DUPLICATE_ROWS].[SignalId]


  -- Store new measurements in the core measurement table.
  INSERT INTO [Core].[Measurement] 
  (
     [Ts]
    ,[Ts_Day]
    ,[SignalId]
    ,[MeasurementValue]
    ,[MeasurementText]
    ,[CreatedAt]
  )
  SELECT 
       i.[Ts] 
      ,CONVERT(DATE, i.[Ts]) as Ts_Day  -- Calculate partition Key, Date type will be converted to DateTime2(0)
      ,CONVERT(INT,           i.[SignalId])
      ,MIN(i.[MeasurementValue])        -- Pick the smaller if more than one arrived
      ,MIN(i.[MeasurementText])
      ,CASE WHEN [SetCreatedAt] = 1 THEN GETUTCDATE()
                                    ELSE NULL
                                    END
  FROM INSERTED as i 
  LEFT OUTER JOIN [Core].[AllMeasurement] as m
      ON  i.[SignalId] = m.[SignalId] 
         AND i.[Ts]       = m.[Ts] 
         AND m.[Ts_Day]   = CONVERT(DATETIME2(0), CONVERT(DATE, i.[Ts]))
  INNER JOIN [Core].[Signal] as s
     ON i.[SignalId] = s.[SignalId] 
  WHERE m.[SignalId]   IS NULL                           -- Really new events
  GROUP BY i.[Ts], i.[SignalId], s.[SetCreatedAt]


  -- Update LatestMeasurement. The table [LatestMeasurement] contains only records if a Signal has defined
  -- [UpdateLatestMeasurement] = 1. If it is set to 0 then the inner join will eliminate the record
  UPDATE [LatestMeasurement]

  SET [LatestMeasurement].[Ts]                 = [LatestInserted].[Ts]
     ,[LatestMeasurement].[MeasurementValue]   = [LatestInserted].[MeasurementValue]
     ,[LatestMeasurement].[MeasurementText]    = [LatestInserted].[MeasurementText]
     ,[CreatedAt]                              = GETUTCDATE()   -- Can be used to check pipeline end-to-end duration
  FROM [Core].[LatestMeasurement]
  INNER JOIN 
      (SELECT 
	         inserted.[SignalId]                   -- The same signal may appear multiple times in the same insert statement,
            ,inserted.[Ts]                    
            ,MAX(inserted.[MeasurementValue])   AS [MeasurementValue]   -- Pick the bigger if more than one arrived
            ,MAX(inserted.[MeasurementText])    AS [MeasurementText]
       FROM inserted
         INNER JOIN (SELECT [SignalId], MAX([Ts]) AS [MaxTs]
                     FROM inserted
                     GROUP BY [SignalId]
      		 	    )                             AS [MaxInsered]
           ON  inserted.[SignalId] = [MaxInsered].[SignalId]
      	  AND  inserted.[Ts]       = [MaxInsered].[MaxTs]
        GROUP BY inserted.[SignalId], inserted.[Ts]
	   )                                                            AS [LatestInserted]
  ON   [LatestMeasurement].[SignalId] = [LatestInserted].[SignalId]
  WHERE [LatestInserted].[Ts] > [LatestMeasurement].[Ts]               -- Late arriving events



  GO