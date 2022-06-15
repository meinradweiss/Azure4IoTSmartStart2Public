CREATE TABLE [Security].[ApplicationRole] (
    [ApplicationRoleGId] UNIQUEIDENTIFIER                            DEFAULT NEWID() NOT NULL,
    [RoleId]             [sysname]                                   NOT NULL,
    [Remark]             VARCHAR (255)                               NULL,
    [CreatedBy]          [sysname]                                   CONSTRAINT [df_role_createdby] DEFAULT (suser_sname()) NOT NULL,
    [ValidFrom]          DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]            DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    PRIMARY KEY NONCLUSTERED ([ApplicationRoleGId] ASC),
    CONSTRAINT [UK_Security_ApplicationUser_RoleId] UNIQUE NONCLUSTERED ([RoleId] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Security].[ApplicationRoleHistory], DATA_CONSISTENCY_CHECK=ON));


GO
CREATE CLUSTERED INDEX [CIX_Security_ApplicationUser_UserId]
    ON [Security].[ApplicationRole]([RoleId] ASC);

