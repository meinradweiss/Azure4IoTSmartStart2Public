CREATE TABLE [Core].[LatestMeasurement] (
    [SignalId]           INT           NOT NULL,
    [Ts]                 DATETIME2 (3) NOT NULL,
    [MeasurementValue]   REAL          NULL, 
    [MeasurementText]    NVARCHAR (4000) NULL,
    [MeasurementContext] NVARCHAR (4000) NULL,
    [CreatedAt]          DATETIME2 (3) NULL,
    CONSTRAINT [PK_CoreLatestMeasurement] PRIMARY KEY NONCLUSTERED ([SignalId])
) 

-- If supoorted from the target plaform e.g. SQL MI BC
--WITH (  
--    MEMORY_OPTIMIZED = ON,  
--    DURABILITY = SCHEMA_AND_DATA);  
