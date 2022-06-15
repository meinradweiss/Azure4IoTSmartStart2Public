IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL
=======================================================================


# API: Stored Procedures, Views and Functions

The following Stored Procedures, Views and Functions act as the API's to the system. They can be used for different purposes like:
- Initial system setup
- Regular system maintenance
- Control activities
- Data extraction

  

<br/>
<br/>
<br/>


** Stored Procedure: [Partition].[MaintainPartitionBorders] **

Creates "empty" partitions for dayPartion Schema/Function and also for the monthPartition Schema/Function. If no parameters are provided, then it will start with the first day of the current month and create partitions for this and the following month.


| Parameter | Data Type | Has<br>default<br>value | Default Value | Purpose |
| :---      | :---:     | :---:                   | :---:         | :---     |
| @startDate | DATETIME2 (0) | 1      | "today" | Specifies the start day to maintain the partition borders. The stored procedure takes this date and then calculates the first day of the corresponding month to define the real start date. |
| @dayAheadNumber | INT | 1 |  35    | The number of days that are added to the current day. The system seeks then forward to the first day of the next month. <br/> e.g. @startDate = '2021-09-07', <br/>the current date is '2021-09-29' and  @dayAheadNumber int = 35 <br/>-> Partitions from 2021-09-01 to 2021-12-01 will be created, <br/> for the dayPartion Schema/Function and also for the monthPartition Schema/Function |


<br/>
<br/>

** Stored Procedure: [Core].[OptimiseDataStorage] **

The stored procedure moves data from the table [Core].[Measurement] (day partition) to the table [Core].[MeasurementStore] (month partition). If no parameters are supplied, then all data arrived two days before the actual day will be moved and the intermediate transfer table will be dropped after the successful transfer.



| Parameter | Data Type | Has<br>default<br>value | Default Value | Purpose |
| :---      | :---:     | :---:                   | :---:         | :---     |
|@MeasureMonthLowWaterMark|DATETIME2(0)|1|1900-01-01| Start "Ts_Day" 'YYYY-MM-DD' value. <br/>Defines the lower boundary from where the optimization starts. The comparison is done using >= logic.
|@MeasureMonthHighWaterMark	|	DATETIME2(0)	|	1	|	9999-12-31	| End "Ts_Day" 'YYYY-MM-DD' value. <br/>Defines the upper boundary from where the optimization starts. The comparison is done using <= logic
|@DropHistoryTable	|	BIT	|	1	|	1	| During the optimization process data is switched out to an intermediate/history table. If the parameter is set to 0 then the switch out table will not be deleted. Otherwise the procedure cleans it up. |



<br/>
<br/>
<br/>


** Stored Procedure: [Core].[RebuildFragmentedIndexes] **

Rebuilds the partitions of the Clustered Index on the [Core].[Measurement] table if the fragmentation is greater than the specified threshold and if the partition relates to a point in time between today -90 days and today -1 day.


| Parameter | Data Type | Has<br>default<br>value | Default Value | Purpose |
| :---      | :---:     | :---:                   | :---:         | :---     |
|@FragmentationLimit|FLOAT|1|80| Threshold to determine if an index will be rebuild



<br/>
<br/>
<br/>

** Stored Procedure: [Partition].[RemoveDataPartitionsFromTable] **

Removes partitions from the specified table


| Parameter | Data Type | Has<br>default<br>value | Default Value | Purpose |
| :---      | :---:     | :---:                   | :---:         | :---     |
|@SchemaName|SYSNAME|0|| Schema name of the source table ('Core').
|@TableName|SYSNAME|0|| Table name of the source table. Either 'Measurement' or 'MeasurementStore'
|@TS_Day_LowWaterMark|DATE|0|| Lower boundary of data, Ts_Day in format 'YYYY-MM-DD', Including this day, compared with >=
|@TS_Day_HighWaterMark|DATE|0|| Upper boundary of data, Ts_Day in format 'YYYY-MM-DD', Including this day, compared with <=
|@PreserveSwitchOutTable|TINYINT|1|0| Data is removed form the table using a switch operation. If this parameter is set to 1, then the switch out table will not be deleted. Otherwise the switch out table will be deleted.


