

CREATE VIEW [Core].[AllMeasurement]
AS

  -- Data from CI table (day partitions)
  SELECT *
  FROM   [Core].[Measurement]

  UNION ALL

  -- Data on the road 2 CCI table
  SELECT *
  FROM   [Core].[MeasurementTransfer]


  UNION ALL

  -- Data from CCI table (month partitions)
  SELECT *
  FROM   [Core].[MeasurementStore]