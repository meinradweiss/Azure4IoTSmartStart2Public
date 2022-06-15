CREATE TABLE [Security].[ApplicationRoleSignalAccess] (
    [ApplicationRoleSignalAccessGId] UNIQUEIDENTIFIER                            DEFAULT NEWID() NOT NULL,
    [RoleId]                         [sysname]                                   NOT NULL,
    [SignalId]                       INT                                         NOT NULL,
    [Remark]                         VARCHAR (255)                               NULL,
    [CreatedBy]                      [sysname]                                   CONSTRAINT [df_applicationroleSignalaccess_createdby] DEFAULT (suser_sname()) NOT NULL,
    [ValidFrom]                      DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]                        DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_security_applicationroleSignalaccess] PRIMARY KEY NONCLUSTERED ([ApplicationRoleSignalAccessGId] ASC),
    CONSTRAINT [FK_ApplicationRoleSignalAccess_ApplicationRole] FOREIGN KEY ([RoleId]) REFERENCES [Security].[ApplicationRole] ([RoleId]),
    CONSTRAINT [FK_ApplicationRoleSignalAccess_Signal] FOREIGN KEY ([SignalId]) REFERENCES [Core].[Signal] ([SignalId]),
    CONSTRAINT [UK_security_applicationroleSignalaccess] UNIQUE CLUSTERED ([RoleId] ASC, [SignalId] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Security].[ApplicationRoleSignalAccessHistory], DATA_CONSISTENCY_CHECK=ON));

