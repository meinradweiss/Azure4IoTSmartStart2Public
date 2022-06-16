IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL
=======================================================================
<br/>


- [IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL](#iot-solutions-using-azure-iot-hub-azure-stream-analytics-and-azure-sql)
  - [Maintain the database](#maintain-the-database)
    - [Add partitions for upcoming days](#add-partitions-for-upcoming-days)
    - [Remove index fragmentation](#remove-index-fragmentation)
    - [Keep long history, use month partitions](#keep-long-history-use-month-partitions)
    - [Remove data from the system](#remove-data-from-the-system)


<br/>


## Maintain the database ##


### Add partitions for upcoming days ###

If the system is up and running, then new data will arrive each day. To keep the system in an optimal state new partitions must be added. For that reason the stored procedure **[Partition].[MaintainPartitionBorders] must be executed once a day**.

<br/> 

Azure Data Factory or Azure Synapse pipelines can be used to schedule the execution. There is no need to specify any parameter to add additional partitions.

<br/>
<br/>

### Remove index fragmentation ###

The table [Core].[Measurement] is organised as a clustered index table on ([SignalId] ASC, [Ts] DESC, [Ts_Day] DESC). This allows very efficient queries that are looking for data of specific Signals [SignalId] and a time window.<br/>
The issue is that data do not arrive in this order and for that reason the index gets immediately fragmented. The good thing is that data mainly arrives at the current day and that older partitions are more or less not modified. The stored procedure **[Core].[RebuildFragmentedIndexes]** detects fragmented partitions and rebuilds them in the background. The procedure should also be **scheduled on a regular basis**. In the ideal case at a time windows with minimal user activity on the system.
<br/>
<br/>
<img src="media\10_21_RebuildFragmentedIndexes.png" width=1100 border=1px>
10_21_RebuildFragmentedIndexes.png
<br/>
<br/>
<br/>

**Stored Procedure: [Core].[RebuildFragmentedIndexes]**

Rebuilds the partitions of the Clustered Index on the [Core].[Measurement] table if the fragmentation is greater than the specified threshold and if the partition relates to a point in time between today -90 days and today -1 day.

| Parameter | Data Type | Has<br>default<br>value | Default Value | Purpose |
| :---      | :---:     | :---:                   | :---:         | :---     |
|@FragmentationLimit|FLOAT|1|80| Threshold to determine if an index will be rebuild

<br/>

Azure Data Factory or Azure Synapse pipelines can be used to schedule the execution. There is no need to specify any parameter to add additional partitions.

<br/>
<br/>
<br/>


### Keep long history, use month partitions ###
If you would like to store historical data for a longer period of time then it makes sense to switch from day partitions to month partitions. The stored procedure [Core].[OptimiseDataStorage] can be used to move data from the day partitions to the corresponding month.
<br/>
The table [Core].[Measurement] uses day partitions (ON [dayPartitionScheme] ([Ts_Day])) and it is organised as a clustered index table on ([SignalId] ASC, [Ts] DESC, [Ts_Day] DESC).
On the other side, the table [Core].[MeasurementStore] uses the month partition schema (ON [monthPartitionScheme] ([Ts_Day])) and is organised as a clustered column store table.
<br/>
<br/>

<img src="media\10_11_OptimiseDataStorage.png" width=1100 border=1px>
10_11_OptimiseDataStorage.png
<br/>
<br/>
<br/>

**Stored Procedure: [Core].[OptimiseDataStorage]**

The stored procedure moves data from the table [Core].[Measurement] (day partition) to the table [Core].[MeasurementStore] (month partition). If no parameters are supplied, then all data arrived two days before the actual day will be moved and the intermediate transfer table will be dropped after the successful transfer.

| Parameter | Data Type | Has<br>default<br>value | Default Value | Purpose |
| :---      | :---:     | :---:                   | :---:         | :---     |
|@MeasureMonthLowWaterMark|DATETIME2(0)|1|1900-01-01| Start "Ts_Day" 'YYYY-MM-DD' value. <br/>Defines the lower boundary from where the optimization starts. The comparison is done using >= logic.
|@MeasureMonthHighWaterMark	|	DATETIME2(0)	|	1	|	9999-12-31	| End "Ts_Day" 'YYYY-MM-DD' value. <br/>Defines the upper boundary from where the optimization starts. The comparison is done using <= logic
|@DropHistoryTable	|	BIT	|	1	|	1	| During the optimization process data is switched out to an intermediate/history table. If the parameter is set to 0 then the switch out table will not be deleted. Otherwise the procedure cleans it up. |

<br/>

Data of the actual day and the day bevore will always be kept in tha table [Core].[Measurement]

<br/>
Azure Data Factory or Azure Synapse pipelines can be used to schedule the execution. There is no need to specify any parameter to add additional partitions.

<br/>
<br/>
<br/>
<br/>

### Remove data from the system ###

Over time the data volume of the database will grow. The stored procedure [Partition].[RemoveDataPartitionsFromTable] can be used to remove data in an efficient way.
The parameter @PreserveSwitchOutTable defines if the switched out data should be kept in the target table or if it should be dropped.
<br/>
<br/>

**Stored Procedure: [Partition].[RemoveDataPartitionsFromTable]**

Removes partitions from the specified table

| Parameter | Data Type | Has<br>default<br>value | Default Value | Purpose |
| :---      | :---:     | :---:                   | :---:         | :---     |
|@SchemaName|SYSNAME|0|| Schema name of the source table ('Core').
|@TableName|SYSNAME|0|| Table name of the source table. Either 'Measurement' or 'MeasurementStore'
|@TS_Day_LowWaterMark|DATE|0|| Lower boundary of data, Ts_Day in format 'YYYY-MM-DD', Including this day, compared with >=
|@TS_Day_HighWaterMark|DATE|0|| Upper boundary of data, Ts_Day in format 'YYYY-MM-DD', Including this day, compared with <=
|@PreserveSwitchOutTable|TINYINT|1|0| Data is removed form the table using a switch operation. If this parameter is set to one, then the switch out table will not be deleted. Otherwise the switch out table will be deleted.

<br/>

Azure Data Factory or Azure Synapse pipelines can be used to schedule the execution of the maintenance stored procedures. 

<br/>
<br/>
<br/>


