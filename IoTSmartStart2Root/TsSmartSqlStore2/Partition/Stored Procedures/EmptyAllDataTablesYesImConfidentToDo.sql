

CREATE PROCEDURE [Partition].[EmptyAllDataTablesYesImConfidentToDo] @AreYouReallySure BIT = 0                         
AS
   -- Attention: Removes all Data from the database!!!

BEGIN

  SET XACT_ABORT ON
  SET NOCOUNT ON

  IF  @AreYouReallySure = 1
  BEGIN

    -- Delete Switch out and History tables

	DECLARE @Sql            NVARCHAR(MAX)
    DECLARE @TablesToDelete CURSOR
    
    SET @TablesToDelete = CURSOR FOR
    SELECT CONCAT('DROP TABLE ', QUOTENAME(SCHEMA_NAME(schema_id)) , '.' , QUOTENAME(name) , ';')
    FROM sys.tables
    WHERE SCHEMA_NAME(schema_id) IN ('Archive','Transfer')
      AND    (name LIKE 'Switched%'
       OR   name LIKE 'History%');
    
      OPEN @TablesToDelete  
    
      FETCH NEXT FROM @TablesToDelete   
      INTO @Sql
    
    
      WHILE @@FETCH_STATUS = 0  
      BEGIN
        EXEC sp_executesql @Sql
    
        FETCH NEXT FROM @TablesToDelete   
          INTO @Sql
    END
	
    CLOSE @TablesToDelete
    DEALLOCATE @TablesToDelete


    -- Delete data from partitioned tables
    EXEC [Partition].[RemoveDataPartitionsFromTable] 'Core', 'Measurement',             19000101, 99991231, 0
    EXEC [Partition].[RemoveDataPartitionsFromTable] 'Core', 'MeasurementTransfer',     19000101, 99991231, 0
    EXEC [Partition].[RemoveDataPartitionsFromTable] 'Core', 'MeasurementStore',        19000101, 99991231, 0
    EXEC [Partition].[RemoveDataPartitionsFromTable] 'Core', 'MeasurementDuplicateKey', 19000101, 99991231, 0

    EXEC [Partition].[RemoveDataPartitionsFromTable] 'Stage', 'Measurement',            19000101, 99991231, 0


    DELETE FROM [Core].[MeasurementWrongMessageFormatOrDataType]

    -- Delete config data
    DELETE FROM [Config].[SignalDefaultConfig]



    -- Begin drop all Transfer tables
    DECLARE @DropTableSQL             NVARCHAR(MAX)

    DECLARE TransferTablesToDelete CURSOR FOR
	SELECT 'DROP TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + ';'
	FROM sys.tables
	WHERE SCHEMA_NAME(schema_id) = 'Transfer'

    OPEN TransferTablesToDelete  
  
    FETCH NEXT FROM TransferTablesToDelete   
    INTO @DropTableSQL

    WHILE @@FETCH_STATUS = 0  
    BEGIN 
      EXEC sp_executesql  @DropTableSQL

      FETCH NEXT FROM TransferTablesToDelete   
      INTO @DropTableSQL
	END
    
	CLOSE      TransferTablesToDelete
	DEALLOCATE TransferTablesToDelete
    -- End drop all Transfer tables

    
    DELETE FROM [Core].[Signal]

    DELETE FROM [Logging].[StepLog]
    DELETE FROM [Logging].[TaskLog]

	ALTER SEQUENCE [Core].[Id]             RESTART WITH 1 ;  
	ALTER SEQUENCE [Logging].[LogSequence] RESTART WITH 1 ;  

	SELECT 'All data removed' as Result
  END
  ELSE
  BEGIN
 	SELECT 'No data removed, please specify @ArYouReallySure = 1 if you would like to remove data' as Result
  END
END
