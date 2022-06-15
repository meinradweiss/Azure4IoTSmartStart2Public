CREATE TABLE [TsHelper].[HourTimeWindowSlot] (
    [TimeWindowStart]     DATETIME2 (3) NOT NULL,
    [TimeWindowEnd]       DATETIME2 (3) NOT NULL,
    [TimeWindowStart_day] DATETIME2 (0) NOT NULL,
    [TimeWindowEnd_day]   DATETIME2 (0) NOT NULL,
    CONSTRAINT [PK_TsHelper_HourTimeWindowSlot] PRIMARY KEY CLUSTERED ([TimeWindowStart] ASC, [TimeWindowEnd] ASC)
);

