CREATE TABLE [Security].[ApplicationRoleMemberHistory] (
    [ApplicationRoleMemberGId] UNIQUEIDENTIFIER NOT NULL,
    [RoleId]                   [sysname]        NOT NULL,
    [UserId]                   [sysname]        NOT NULL,
    [Remark]                   VARCHAR (255)    NULL,
    [CreatedBy]                [sysname]        NOT NULL,
    [ValidFrom]                DATETIME2 (7)    NOT NULL,
    [ValidTo]                  DATETIME2 (7)    NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_ApplicationRoleMemberHistory]
    ON [Security].[ApplicationRoleMemberHistory]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);

