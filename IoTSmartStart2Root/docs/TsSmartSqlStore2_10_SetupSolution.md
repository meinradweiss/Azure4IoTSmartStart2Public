IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL
=======================================================================
<br/>


- [IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL](#iot-solutions-using-azure-iot-hub-azure-stream-analytics-and-azure-sql)
- [Setup and operate the solution](#setup-and-operate-the-solution)
- [Development environment](#development-environment)
- [Get access to the code](#get-access-to-the-code)
- [Install Azure Services](#install-azure-services)
  - [Prepare data database](#prepare-data-database)
    - [Create Users in the database](#create-users-in-the-database)
    - [Deploy the database schema to your database](#deploy-the-database-schema-to-your-database)
    - [Initialize partitions](#initialize-partitions)
    - [Define (default) behaviour of Measurand(s)](#define-default-behaviour-of-measurands)
  - [Optionally: Prepare the Azure IoT hub and Raspberry-pi emulator](#optionally-prepare-the-azure-iot-hub-and-raspberry-pi-emulator)
  - [Optionally: Configure the Raspberry Pi sample application](#optionally-configure-the-raspberry-pi-sample-application)
  - [Maintain the database](#maintain-the-database)
    - [Add partitions for upcoming days](#add-partitions-for-upcoming-days)
    - [Remove index fragmentation](#remove-index-fragmentation)
    - [Keep long history, use month partitions](#keep-long-history-use-month-partitions)
    - [Remove data from the system](#remove-data-from-the-system)
  - [Modify Stream Analytics project](#modify-stream-analytics-project)
    - [Configure Stream Analytics Storage Account](#configure-stream-analytics-storage-account)
    - [Define connection information of Inputs](#define-connection-information-of-inputs)
      - [CoreSignal](#coresignal)
      - [IoTDataInput](#iotdatainput)
    - [Define connection information of Outputs](#define-connection-information-of-outputs)
    - [Adjust the Stream Analytics Query](#adjust-the-stream-analytics-query)
  - [Test your system](#test-your-system)


<br/>

# Setup and operate the solution #

The following steps are required to setup the solution:
- Install the necessary development tools
- Get access to the code
- Install Azure Services (Azure Stream Analytics and Azure SQL Database)
- Deploy SQL Database schema
- Initialise partitions
- Deploy Stream Analytics Jobs

After the initial setup some maintenance activities should be executed to keep the system in an optimal shape.

# Development environment #

The solution is currently only compatible with Visual Studio 2019 and 2022.

When using Visual Studio 2019 make sure the following toolset is installed:

![Visual Studio 2019 Packages](media/vs_packages2019.png)

When using Viusl Studio 2022 make sure the following packages are installed:

![Visual Studio 2022 Packages](media/vs_packages2022.png)

# Get access to the code #

This chapter describes how to deploy the source code into the created Azure components from the step before.

Before starting with the deployment, please make sure that the Azure services have been deployed and the necessary tool pre-requisites have been installed on your local machine.

Clone the following github repository to your local computer:

```
git clone https://github.com/meinradweiss/Azure4IoTSmartStart2Public
```

**The github repository is currently private, please reach out to the repository owner to get access.**

# Install Azure Services #

The following button deploys the core infrastructure into your chosen subscription.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fyaens%2Farm-templates%2Fmaster%2Fstartsmart%2FazuredeployBasic.json)



For the custom deployment, the following parameters need to be defined:
- Region: Select your designated Azure Region, make sure to pick a region which supports the necessary components
- Unique Solution Prefix: Pick a unique string for your solution. The name must be between 3 and 24 characters in length and use numbers and lower-case letters only
- Sql Administrator Login: pick an username for your SQL administrator
- Sql Administrator Login Password: define a strong password for your SQL administrator. It has to include small letters, capital letters, a number and a special character
- Sql Firewall Start IP: Add the public IP of your computer to this field, for testing purposes you can use ```0.0.0.0```
- Sql Firewall End IP: Add the public IP of your computer to this field, for testing purposes you can use ```255.255.255.255```

If you would like to deploy the services from you local machine you can find the arm templates and a supporting deployment script in the ```infrastructure``` folder.

## Prepare data database ##

### Create Users in the database ###

Create the database user(s) to allow Azure Stream Analytics to connect to the database, read meta data ([Core].[Signal]) and write telemetry data.

The recommended way is to work with the managed identity of Stream Analytics. But currently Visual Studio does not allow to use managed identities in the project file. You can change the connection properties after deploying the solution to Azure.

If you would like to setup SQL users based on the managed identiy, then you must login to the SQL database with an Azure AD user identity. This requires, that you are either Azure Active Directory admin on your database server or that some created a user with your Azure AD indentity.

-- Managed Identity<br/>
CREATE USER [aaadeletemewstreamanalytics] FROM EXTERNAL PROVIDER; <br/>
GRANT SELECT ON OBJECT::[Core].[Signal] TO [aaadeletemewstreamanalytics] ;<br/>
GRANT SELECT, INSERT ON SCHEMA::INGEST TO [aaadeletemewstreamanalytics];<br/>
<br/>
-- Database User<br/>
CREATE USER [ASA_MetaDataReader]   WITH PASSWORD = 'your strong password 8fdKdd$nlNv3049jsKK';<br/>
CREATE USER [ASA_TelemetryWriter]  WITH PASSWORD = 'your strong password 8fdKsd3$nlNv3049jsZZ';<br/>

GRANT SELECT ON OBJECT::[Core].[Signal] TO [ASA_MetaDataReader] ;<br/>
GRANT SELECT, INSERT ON SCHEMA::INGEST  TO [ASA_TelemetryWriter] ;<br/>

### Deploy the database schema to your database ###

Open the solution in Visual Studio and then open the SchemaCompare file: InitialDeploySqlSchemaCompare.scmp. Configure the target database -> point it to your Azure SQL database. Press the [Compare], check the differences and press [Update]<br/>
<br/>

For any further updates you should use the SchemaCompare file: RegularDeploySqlSchemaCompare.scmp


### Initialize partitions ###
A key aspect of the solution is the fact that the large tables are partitioned. The solution just contains one partition border with the value '1900-01-01 00:00:00'. The first step after deploying the solution to the database is to create the real partitions which matches to the data that will be stored in the database. <br/>
The stored procedure [Partition].[MaintainPartitionBorders] can be used to do an initial setup and it must be scheduled to adjust the borders on a regular basis. Azure Data Factory or Azure Synapse Analytics Pipelines can be used to setup the scheduled execution.
<br/>

![Visual Studio 2022 Packages](media\10_01_PartitionStructure.png)


**Stored Procedure: [Partition].[MaintainPartitionBorders]**

Creates "empty" partitions for dayPartion and monthPartition Schema/Function. If no parameters are provided, then it will start with the first day of the current month and create partitions for this and the following month.

| Parameter | Data Type | Has<br>default<br>value | Default Value | Purpose |
| :---      | :---:     | :---:                   | :---:         | :---     |
| @startDate | DATETIME2 (0) | 1      | "today" | Specifies the start day to maintain the partition borders. The stored procedure takes this date and then calculates the first day of the corresponding month to define the real start date. |
| @dayAheadNumber | INT | 1 |  35    | The number of days that are added to the current day. The system seeks then forward to the first day of the next month. <br/> e.g. @startDate = '2021-09-07', <br/>the current date is '2021-09-29' and  @dayAheadNumber int = 35 <br/>-> Partitions from 2021-09-01 to 2021-12-01 will be created, <br/> for the dayPartion Schema/Function and also for the monthPartition Schema/Function |

If you would like to load historical data to the database, then you should specify the @startDate parameter. It should be set to the first date of the historical data.

<br/>
<br/>
<br/>


### Define (default) behaviour of Measurand(s) ###
The table [Core].[Signal] stores the list of all reference signals and they provide the context for all stored Measurement data. Beside of that context they also steer the behavior of the system via the values of the two attributes [UpdateLatestMeasurement] and [SetCreatedAt].

- [Core].[LatestMeasurement] 
<br/>
The table [Core].[LatestMeasurement] stores the latest known value of a Signal. This is very useful if you build a dashboard on top of the database to visualize the current state. Maintaining this table generates additional work for the database. That's the reason why the feature is disabled per default. If the last value of a signal should be maintained in the table [Core].[LatestMeasurement], then the [UpdateLatestMeasurement] of the corresponding Signal in the table [Core].[Signal] must be set to 1 (true).
Setting the attribute to 1 will not only change the attribute value but also add an entry in the [Core].[LatestMeasurement] table and scans [Core].[AllMeasurement] to find the last know value. If the database already contains a lot of rows, then this process can thake a while. For that reason it is recommended to change not a lot of records in one transaction. 
<br/>
- [Core].[Measurement<xyz>].[CreatedAt]
<br/>
The attribute [CreatedAt] can optionally store the point in time when the record is stored in the database. If this information is stored with eache Measurement, then the required storage space witll grow, but it is possible to analyse the latency of the whole chain (Time between the event is generated and the time when it arrives in the database). Also this feature is per default disabled and it can be enabled by changing the value of the attribute [SetCreatedAt] in the table [Core].[Signal] to 1 (true).
<br/>

If new signals are registered, then the values of [UpdateLatestMeasurement] and [SetCreatedAt] are 0 (false). If there are measurands for which you would like to change the default behaviour, then you do that by adding the measurand and the desired values for [UpdateLatestMeasurement] and [SetCreatedAt] in the table [Config].[SignalDefaultConfig].
<br/>
<br/>
<br/>



## Optionally: Prepare the Azure IoT hub and Raspberry-pi emulator  ##

If you don't have an existing Azure IoT hub with devices already generating events, then you can create your own device and generate your own telemetry data. <br/>

Open in the azure portal your Azure IoT hub and create a new device: 

<br/>
<br/>

## Optionally: Configure the Raspberry Pi sample application ##

https://azure-samples.github.io/raspberry-pi-web-simulator/




    /*
    * IoT Hub Raspberry Pi NodeJS - Microsoft Sample Code - Copyright (c) 2017 - Licensed MIT
    */
    const wpi = require('wiring-pi');
    const Client = require('azure-iot-device').Client;
    const Message = require('azure-iot-device').Message;
    const Protocol = require('azure-iot-device-mqtt').Mqtt;
    const BME280 = require('bme280-sensor');

    const BME280_OPTION = {
      i2cBusNo: 1, // defaults to 1
      i2cAddress: BME280.BME280_DEFAULT_I2C_ADDRESS() // defaults to 0x77
    };

    const connectionString = 'HostName=<YourHub>.azure-devices.net;DeviceId=MewSampeDevice01;SharedAccessKey=<YourKey>';
    const LEDPin = 4;

    var sendingMessage = false;
    var messageId = 0;
    var client, sensor;
    var blinkLEDTimeout = null;

    function getMessage(cb) {
      messageId++;
      sensor.readSensorData()
        .then(function (data) {
          cb(JSON.stringify({
            messageId: messageId,
            deviceId: 'Raspberry Pi Web Client',
            temperature: data.temperature_C,
            humidity: data.humidity,
            eventTimestamp: (new Date()).toISOString()
          }), data.temperature_C > 30);
        })
        .catch(function (err) {
          console.error('Failed to read out sensor data: ' + err);
        });
    }

    function sendMessage() {
      if (!sendingMessage) { return; }

      getMessage(function (content, temperatureAlert) {
        var message = new Message(content);
        message.properties.add('temperatureAlert', temperatureAlert.toString());
        console.log('Sending message: ' + content);
        client.sendEvent(message, function (err) {
          if (err) {
            console.error('Failed to send message to Azure IoT Hub');
          } else {
            blinkLED();
            console.log('Message sent to Azure IoT Hub');
          }
        });
      });
    }

    function onStart(request, response) {
      console.log('Try to invoke method start(' + request.payload + ')');
      sendingMessage = true;

      response.send(200, 'Successully start sending message to cloud', function (err) {
        if (err) {
          console.error('[IoT hub Client] Failed sending a method response:\n' + err.message);
        }
      });
    }

    function onStop(request, response) {
      console.log('Try to invoke method stop(' + request.payload + ')');
      sendingMessage = false;

      response.send(200, 'Successully stop sending message to cloud', function (err) {
        if (err) {
          console.error('[IoT hub Client] Failed sending a method response:\n' + err.message);
        }
      });
    }

    function receiveMessageCallback(msg) {
      blinkLED();
      var message = msg.getData().toString('utf-8');
      client.complete(msg, function () {
        console.log('Receive message: ' + message);
      });
    }

    function blinkLED() {
      // Light up LED for 500 ms
      if(blinkLEDTimeout) {
          clearTimeout(blinkLEDTimeout);
      }
      wpi.digitalWrite(LEDPin, 1);
      blinkLEDTimeout = setTimeout(function () {
        wpi.digitalWrite(LEDPin, 0);
      }, 500);
    }

    // set up wiring
    wpi.setup('wpi');
    wpi.pinMode(LEDPin, wpi.OUTPUT);
    sensor = new BME280(BME280_OPTION);
    sensor.init()
      .then(function () {
        sendingMessage = true;
      })
      .catch(function (err) {
        console.error(err.message || err);
      });

    // create a client
    client = Client.fromConnectionString(connectionString, Protocol);

    client.open(function (err) {
      if (err) {
        console.error('[IoT hub Client] Connect error: ' + err.message);
        return;
      }

      // set C2D and device method callback
      client.onDeviceMethod('start', onStart);
      client.onDeviceMethod('stop', onStop);
      client.on('message', receiveMessageCallback);
      setInterval(sendMessage, 500);  //2000
    });



## Maintain the database ##


### Add partitions for upcoming days ###

If the system is up and running, then new data will arrive each day. To keep the system in an optimal state new partitions must be added. For that reason the stored procedure [Partition].[MaintainPartitionBorders] must be executed once a day.

<br/> 

Azure Data Factory or Azure Synapse pipelines can be used to schedule the execution. There is no need to specify any parameter to add additional partitions.

<br/>
<br/>

### Remove index fragmentation ###

The table [Core].[Measurement] is organised as a clustered index table on ([SignalId] ASC, [Ts] DESC, [Ts_Day] DESC). This allows very efficient queries that are looking for data of specific Signals [SignalId] and a time window.<br/>
The issue is that data do not arrive in this order and for that reason the index gets immediately fragmented. The good thing is that data mainly arrives at the current day and that older partitions are more or less not modified. The stored procedure [Core].[RebuildFragmentedIndexes] detects fragmented partitions and rebuilds them in the background. The procedure should also be scheduled on a regular basis. In the ideal case at a time windows with minimal user activity on the system.
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


## Modify Stream Analytics project ##

### Configure Stream Analytics Storage Account ###

Stream Analytics needs a storage account to get reference data from SQL Server. The definition of the storage acccount is stored in the file JobConfig.json. The storage account definitions are located in the [Global Storage Settings] tab.

### Define connection information of Inputs ###

The following tho inputs must be adjusted to your environment: CoreSignal, IoTDataInput

#### CoreSignal ####

Define the connection to your SQL Server using the user ASA_MetaDataReader. You can switch to the managed identity, as soon as the solution is deployed to Stream Analytics

#### IoTDataInput ####

Define the connection to your IoTHub

### Define connection information of Outputs ###

The following tho outputs must be adjusted to your environment: Measurement, MeasurementWithSignalName, MeasurementWrongMessageFormatOrDataType

Specify the connection string to your database server and specify the user ASA_TelemetryWriter while you are using visual studio to test. After deploying the solution to stream Analytics you can change it to the managed identity.

### Adjust the Stream Analytics Query ###

Modify the query,that it fits to your message. You only need to adjust the piece in the block 'section to be adjusted'

<br/>

If you are using the Raspberry Pi sample application to generate the IoT events, then you can use the following script to parse the message. There is a Github sample project (https://github.com/meinradweiss/StreamAnalyticsQuery) that may be helpful if you would like to parse your own messages.



    -- Begin of section to be adjusted

      WITH ParsedMessage
      AS
      (
        SELECT
           IotDataInput.deviceId
          ,IotDataInput.eventTimestamp
          ,Property.propertyName                         AS Measurand
          ,Property.propertyValue                        AS MeasurementValue
        ,IotDataInput
          FROM [IotDataInput]
          CROSS APPLY GetRecordProperties(IotDataInput)   AS Property
          WHERE Property.propertyname = 'temperature'
            OR Property.propertyname = 'humidity'
      
      )
      
      ,IoTDataInputWithSignalName  
      AS
      (
      
        SELECT 
          TRY_CAST(eventTimestamp AS DATETIME)                            AS [Ts]
          ,deviceId                                                       AS [DeviceId]
          ,Measurand                                                      AS [Measurand]
          ,CONCAT(deviceId, '_', Measurand)                               AS [SignalName]
          ,TRY_CAST([MeasurementValue] AS FLOAT)                          AS [MeasurementValue]
          ,CASE WHEN LEN([MeasurementValue]) > 0 
                  AND TRY_CAST([MeasurementValue] AS FLOAT) IS NULL 
                                                  THEN [MeasurementValue]  
                                        ELSE NULL 
            END                                                            AS [MeasurementText]
          ,eventTimestamp                                                 AS [SourceTS]
          ,[MeasurementValue]                                             AS [SourceMeasurementValue]
          ,[MeasurementValue]                                             AS [SourceMeasurementText]
          
          ,IotDataInput                                                   AS [SourceMessage]
        FROM [ParsedMessage]
      )

    -- End of section to be adjusted


    ### Submit the Strem Analytics project to Azrue ###

## Test your system ##

Make sure that events are submitted to your IotHub. If your are using the Raspberry Pi sample application, then press run

Execute in your SQL Server database the stored proecdure [Core].[GetOverviewOfDataInDatabase]<br/>

    exec [Core].[GetOverviewOfDataInDatabase]