
CREATE PROCEDURE [Partition].[GetPartition_Number]
        @SchemaName         sysname
       ,@TableName          sysname
	   ,@Ts_Day             INT
	   ,@Partition_Number   INT OUTPUT

AS

BEGIN

  SET NOCOUNT ON

  -- Dynamic SQL is not allowed in a function -> Code implemented as Stored Procedure

  DECLARE @PartitionFunctionName SYSNAME



  SELECT  @PartitionFunctionName = PartitionFunctionName
  FROM   [Partition].[TablePartitionFunction]
  WHERE  SchemaName = @SchemaName
    AND  TableName  = @TableName

  DECLARE @SQL NVARCHAR(MAX)
  SET @SQL = 'SELECT @Partition_Number = $PARTITION.' + @PartitionFunctionName + '(' + CONVERT(NVARCHAR, @Ts_Day) + ')'
  EXECUTE sp_executesql @SQL, N'@Partition_Number INT OUTPUT', @Partition_Number=@Partition_Number OUTPUT

END