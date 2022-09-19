CREATE TABLE [Core].[TsDay] (
    [Ts_Day]         INT             NOT NULL,
    [Ts_Date]        DATE            NOT NULL,
    [MonthNumber]    INT             NOT NULL,
    [MonthName]      NVARCHAR (30)   NOT NULL,
    [WeekDayNumber]  INT             NOT NULL,
    [WeekDay]        NVARCHAR (30)   NOT NULL,
    [WeekNumber]     NVARCHAR (30)   NOT NULL,
    [Iso_WeekNumber] NVARCHAR (30)   NOT NULL,
    CONSTRAINT [PK_Core_TsDay] PRIMARY KEY CLUSTERED ([Ts_Day] DESC)
);

