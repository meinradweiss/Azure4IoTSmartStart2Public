CREATE PROCEDURE [Core].[GetOverviewOfDataInDatabase]
AS
BEGIN


  SELECT TOP 5 'Table: [Core].[Signal]' AS [Source], *
  FROM [Core].[Signal]
  ORDER BY [CreatedAt] DESC

  SELECT TOP 5 'Table: [Mart].[Measurement]' AS [Source], *
  FROM [Mart].[Measurement]
  ORDER BY [Ts] DESC

 SELECT TOP 5 'Table: [Core].[Measurement]' AS [Source], *
  FROM [Core].[Measurement]
  ORDER BY [Ts] DESC

  SELECT TOP 5 'Table: [Core].[MeasurementTransfer]' AS [Source], *
  FROM [Core].[MeasurementTransfer]
  ORDER BY [Ts] DESC

  SELECT TOP 5 'Table: [Core].[MeasurementStore]' AS [Source], *
  FROM [Core].[MeasurementStore]
  ORDER BY [Ts] DESC

  SELECT TOP 5 'Table: [Core].[MeasurementDuplicateKey]' AS [Source], *
  FROM [Core].[MeasurementDuplicateKey]
  ORDER BY [CreatedAt] DESC

  SELECT TOP 5 'Table: [Core].[MeasurementWrongMessageFormatOrDataType]' AS [Source], *
  FROM [Core].[MeasurementWrongMessageFormatOrDataType]
  ORDER BY [CreatedAt] DESC

  SELECT 'Table: [Core].[LatestMeasurement]' AS [Source], *
  FROM [Core].[LatestMeasurement]

  SELECT 'Table: [Core].[Signal]'                                  as Source, COUNT(*) FROM [Core].[Signal]
  SELECT 'Table: [Core].[Measurement]'                             as Source, COUNT(*) FROM [Core].[Measurement]
  SELECT 'Table: [Core].[MeasurementTransfer]'                     as Source, COUNT(*) FROM [Core].[MeasurementTransfer]
  SELECT 'Table: [Core].[MeasurementStore]'                        as Source, COUNT(*) FROM [Core].[MeasurementStore]
  SELECT 'Table: [Core].[MeasurementDuplicateKey]'                 as Source, COUNT(*) FROM [Core].[MeasurementDuplicateKey]
  SELECT 'Table: [Core].[MeasurementWrongMessageFormatOrDataType]' as Source, COUNT(*) FROM [Core].[MeasurementWrongMessageFormatOrDataType]

  SELECT TOP 100 'Table: ' AS [Source],*
  FROM     [Logging].[LogInfo]
  ORDER BY [StepStartTime] DESC



  SELECT 'A Table: [Core].[Measurement]'                   AS Source
        , Ts_Day                                      AS Ts_Day
   	    , $PARTITION.dayPartitionFunction(Ts_Day)     AS PartitionNr
   	    , COUNT(*)                                    AS Rows 
  FROM [Core].[Measurement] 
  GROUP BY Ts_Day

  UNION ALL

  SELECT 'B Table: [Core].[MeasurementTransfer]'           AS Source
       , Ts_Day                                      AS Ts_Day
   	   , $PARTITION.dayPartitionFunction(Ts_Day)     AS PartitionNr
   	   , COUNT(*)                                    AS Rows 
  FROM [Core].[MeasurementTransfer] 
  GROUP BY Ts_Day
   
  UNION ALL

  SELECT 'C Table: [Core].[MeasurementStore]'              AS Source
        , Ts_Day                                      AS Ts_Day
   	    , $PARTITION.MonthPartitionFunction(Ts_Day)   AS PartitionNr
   	    , COUNT(*)                                    AS Rows 
  FROM [Core].[MeasurementStore] 
  GROUP BY Ts_Day
  
  ORDER BY 1,2 DESC;


END

