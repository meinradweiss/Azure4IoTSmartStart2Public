CREATE TABLE [Security].[ApplicationRoleSignalAccessHistory] (
    [ApplicationRoleSignalAccessGId] UNIQUEIDENTIFIER NOT NULL,
    [RoleId]                         [sysname]        NOT NULL,
    [SignalId]                       INT              NOT NULL,
    [Remark]                         VARCHAR (255)    NULL,
    [CreatedBy]                      [sysname]        NOT NULL,
    [ValidFrom]                      DATETIME2 (7)    NOT NULL,
    [ValidTo]                        DATETIME2 (7)    NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_ApplicationRoleSignalAccessHistory]
    ON [Security].[ApplicationRoleSignalAccessHistory]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);

