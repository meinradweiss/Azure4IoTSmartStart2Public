CREATE TABLE [Config].[SystemConfig] (
    [SystemConfigGId]   UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [SystemConfigId]    INT              DEFAULT (NEXT VALUE FOR [Core].[Id]) NOT NULL,
    [SystemConfigName]  NVARCHAR (256)   NOT NULL,
    [SystemConfigValue] SQL_VARIANT      NOT NULL,
    [CreatedAt]         DATETIME2 (3)    DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY NONCLUSTERED ([SystemConfigGId] ASC),
    CONSTRAINT [Core_SystemConfig] UNIQUE NONCLUSTERED ([SystemConfigId] ASC),
    CONSTRAINT [UK_CoreSystemConfig_SystemConfigName] UNIQUE NONCLUSTERED ([SystemConfigName] ASC)
);

