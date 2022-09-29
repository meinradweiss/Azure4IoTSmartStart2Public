ImportExistingTelemetryData - IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL
=======================================================================


<br/>

- [ImportExistingTelemetryData - IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL](#importexistingtelemetrydata---iot-solutions-using-azure-iot-hub-azure-stream-analytics-and-azure-sql)
- [Overview](#overview)
  - [Stage Tables](#stage-tables)
  - [Store Procedure \[Stage\].\[LoadTransferData\]](#store-procedure-stageloadtransferdata)
  - [Import process](#import-process)


<br/>



# Overview

If you have existing telemetry data that you would like to import to this database, then you can use the objects in the database schema [Stage]. <br/> It can be helpful if you have to migrate from an older version of the soltuion where the partition key changed.

## Stage Tables ##

The schema [Stage] contains the following objects:
- Tables
  - [Stage].[Measurement] 
  
 | Object Name | Type | Remark |
| :---      | :---     | :---     |
|  [Stage].[Measurement] | Table | 
|  [Stage].[Signal] | Table | Signal reference records. Each signal referenced in [Stage].[Measurement] must be available in this table. Make sure that you don't get any overlap with SignalId's in the table [Core].[Signal]
|  [Stage].[SignalDefaultConfig] | Table | Existing configuration data |
|  [Stage].[LoadTransferData] | Procedure | Transfer data from [Stage] to [Core]

<br/>
<br/>

## Store Procedure [Stage].[LoadTransferData] ##

| Parameter | Data Type | Has<br>default<br>value | Default Value | Purpose |
| :---      | :---:     | :---:                   | :---:         | :---     |
| @From_Ts_Day | INT | 1      | 19000101 | Specifies the start TS_Day that should be transferred. <br/>Compared with the logic >= |
| @To_Ts_Day | INT | 1      | 99991231 | Specifies the end TS_Day that should be transferred. <br/>Compared with the logic <= |
| @HighWaterMarkMeasuremtStore | INT | 1 |  19000101    |All Ts_Day data 'older' than this value will be loaded to [Core].[MeasurementStore], instead of [Core].[Measurement |


<br/>

<br/>
## Import process ##

Copy existing data to the corresponding [Stage] tables and execute the stored procedure [Stage].[LoadTransferData]. If you have a huge dataset, then it is possible to load all data into [Stage].[Signal]/[Stage].[SignalDefaultConfig] and execute the procedure [Stage].[LoadTransferData] with just one day in the @From_Ts_Day : @To_Ts_Day. After the first day is processed, you can start the Stream Analytics job to load actual telemetry data to the database and load the rest of the 'historical' data day by day. If you start with the newest days, then user will se the probaly most important data at first.

