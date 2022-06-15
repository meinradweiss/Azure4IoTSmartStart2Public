CREATE TABLE [Security].[ApplicationUser] (
    [ApplicationUserGId] UNIQUEIDENTIFIER                            DEFAULT NEWID() NOT NULL,
    [UserId]             [sysname]                                   NOT NULL,
    [Remark]             VARCHAR (255)                               NULL,
    [CreatedBy]          [sysname]                                   CONSTRAINT [df_Security_ApplicationUser_createdby] DEFAULT (suser_sname()) NOT NULL,
    [ValidFrom]          DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]            DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    PRIMARY KEY NONCLUSTERED ([ApplicationUserGId] ASC),
    CONSTRAINT [UK_Security_ApplicationUser_UserId] UNIQUE NONCLUSTERED ([UserId] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Security].[ApplicationUserHistory], DATA_CONSISTENCY_CHECK=ON));


GO
CREATE CLUSTERED INDEX [CIX_Security_ApplicationUser_UserId]
    ON [Security].[ApplicationUser]([UserId] ASC);

