
CREATE VIEW [Partition].[PartitionRangeValues]
AS

WITH AllRanges
AS
(
  SELECT pf.name                               AS PartitionFunctionName                           
       , pr.boundary_id                        AS Boundary_id
  	 , (SELECT MAX(value) 
  	    FROM   sys.partition_range_values 
  		WHERE  boundary_id < pr.boundary_id 
  		  AND function_id  = pr.function_id) AS FromValue
       , pr.value                              AS LowerThanValue
  FROM   sys.partition_range_values AS pr
    INNER JOIN sys.partition_functions AS pf
      ON pr.function_id = pf.function_id
  
  UNION ALL
  
  SELECT pf.name
       , max(pr.boundary_id) + 1
       , max(pr.value) as FromValue
  	 , NULL          as LowerThanValue
  FROM   sys.partition_range_values AS pr
    INNER JOIN sys.partition_functions AS pf
      ON pr.function_id = pf.function_id
  GROUP BY pf.name
)
SELECT TOP 100000000 *
FROM AllRanges
ORDER BY 1,2