

CREATE FUNCTION [Partition].[GetPartitionRangeCheckConstraint]
(
        @SchemaName         SYSNAME
       ,@TableName          SYSNAME
	   ,@Partition_Number   INT
)
RETURNS nvarchar(max)    

AS
BEGIN


  DECLARE @LowerBoundaryValue   INT
		 ,@UpperBoundaryValue   INT




  SELECT @LowerBoundaryValue = CONVERT(INT,FromValue)
        ,@UpperBoundaryValue = CONVERT(INT,LowerThanValue)
  FROM   [Partition].[PartitionRangeValues]          AS Pr
    INNER JOIN [Partition].[TablePartitionFunction]  AS TPf
      ON Pr.PartitionFunctionName = TPf.PartitionFunctionName
  WHERE SchemaName  = @SchemaName
    AND TableName   = @TableName
    AND Boundary_id = @Partition_Number

  DECLARE @CheckConstraintSQL nvarchar(max)       

  IF @partition_number = 1
    SET @CheckConstraintSQL = CONCAT('CHECK ([Ts_Day]  < ', @LowerBoundaryValue,') ')
  ELSE
    SET @CheckConstraintSQL = CONCAT('CHECK ([Ts_Day]  >= ', @LowerBoundaryValue,' AND  [Ts_Day] < ', @UpperBoundaryValue ,')')
  IF @UpperBoundaryValue IS NULL
    SET @CheckConstraintSQL = CONCAT('CHECK ([Ts_Day]  >= ', @LowerBoundaryValue,') ')

  RETURN @CheckConstraintSQL
END