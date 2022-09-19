Version Info and Configuration Settings - IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL
=======================================================================


<br/>

- [Version Info and Configuration Settings - IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL](#version-info-and-configuration-settings---iot-solutions-using-azure-iot-hub-azure-stream-analytics-and-azure-sql)
- [Version Info](#version-info)
- [System Configuration](#system-configuration)


<br/>



# Version Info #

The view [Core].[VersionInfo] contains the information regarding the current version of the database schema.


    select *
    from [Core].[VersionInfo]

<br/>

# System Configuration #

The table [Config].[SystemConfig] can be used to configure the solution. 

The following keys are used by the system itself. If the keys don't exist in the table, then default values are used.

 | Key [SystemConfigName] | Value(s) [SystemConfigValue] | Remark | Default Value |
| :---      | :---     | :---     |:---     |
|  DebugMode | 'None'/'Verbose' | In Verbose mode important dynamic SQL will also be printed while executed. | None |
| LocalTimezone | Any valid SQL Server time zone | Used to tanslate _UTC times to local time values. | 'Central European Standard Time'|

<br/>

The stored procedure [Config].[SetDebugMode] can be used to quickly swith the debug mode settings. Allowed parameters are: 'None' or 'Verbose'