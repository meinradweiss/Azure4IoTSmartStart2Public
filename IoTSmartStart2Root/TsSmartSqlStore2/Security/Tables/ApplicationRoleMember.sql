CREATE TABLE [Security].[ApplicationRoleMember] (
    [ApplicationRoleMemberGId] UNIQUEIDENTIFIER                            DEFAULT NEWID() NOT NULL,
    [RoleId]                   [sysname]                                   NOT NULL,
    [UserId]                   [sysname]                                   NOT NULL,
    [Remark]                   VARCHAR (255)                               NULL,
    [CreatedBy]                [sysname]                                   CONSTRAINT [df_rolemember_createdby] DEFAULT (suser_sname()) NOT NULL,
    [ValidFrom]                DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]                  DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_security_applicationrolemember] PRIMARY KEY NONCLUSTERED ([ApplicationRoleMemberGId] ASC),
    CONSTRAINT [FK_ApplicationRoleMember_ApplicationRole] FOREIGN KEY ([RoleId]) REFERENCES [Security].[ApplicationRole] ([RoleId]),
    CONSTRAINT [FK_ApplicationRoleMember_ApplicationUser] FOREIGN KEY ([UserId]) REFERENCES [Security].[ApplicationUser] ([UserId]),
    CONSTRAINT [UK_security_applicationrolemember] UNIQUE CLUSTERED ([UserId] ASC, [RoleId] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Security].[ApplicationRoleMemberHistory], DATA_CONSISTENCY_CHECK=ON));


GO
CREATE STATISTICS [sts_security_applicationrolemember_roleid]
    ON [Security].[ApplicationRoleMember]([RoleId]);

