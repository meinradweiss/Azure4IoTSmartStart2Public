IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL
=======================================================================

<br/>

- [IoT solutions using Azure IoT Hub, Azure Stream Analytics and Azure SQL](#iot-solutions-using-azure-iot-hub-azure-stream-analytics-and-azure-sql)
- [Main Architecture](#main-architecture)
  - [Covered Business Requirements](#covered-business-requirements)

<br/>
<br/>

# Main Architecture #

The solution is built using the following Azure PaaS Services:

- Azure IoT Hub
- Azure Stream Analytics
- Azure SQL 

<br/>
<br/>

<img src="media\01_Overview.png" width=900>
01_Overview.png

<br/>
<br/>

The used PaaS services provide a huge set of functionalities to implement a secure, flexible, scalable, and maintainable IoT solution with a minimal part of self-written code.

<br/>
<br/>

## Covered Business Requirements
The following business requirements:
-	Deal with mal formed events
    - If events don’t contain the expected data types or if lookup records in the meta data database are missing, then these records should be stored in a separate table
-	Avoid duplicate delivery of events
    -  Every event should be stored once and only once in a SQL table. If the same event is delivered multiple times, then the duplicates should be stored in a separate table
-	Show data only allowed rows, company internal but also for third party users
    -  Role based “row level security” should steer who can see what
- 	Keep history of all security relevant meta data changes
    - All changes on “row level security” relevant data must be kept on the system
-	Optimise speed and storage space needed. 
    - The from the source provided device name should be mapped to an internal device-/signalId

<br/>
<br/>

<img src="media\02_BusinessRequirements.png" width=900>
02_BusinessRequirements.png  
  
  

<br/>
<br/>
<br/>
