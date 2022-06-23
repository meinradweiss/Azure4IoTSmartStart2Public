CREATE FUNCTION [Mart].[GetRelativeTimeWindow] 
  (  @DeltaTime        VARCHAR(25)
    ,@UtcEndDateTime   DATETIME2(3) = NULL
	,@DefaultTimeZone  VARCHAR(50) = 'Central European Standard Time' 
  )
RETURNS TABLE
AS 
RETURN 


  WITH EndDatetime
  AS
  (
     -- '9999-12-31 23:59:59.999' case is for Power BI parameters 
     SELECT CASE WHEN @UtcEndDateTime IS NULL OR @UtcEndDateTime = CONVERT(DATETIME2(3), '9999-12-31 23:59:59',121) THEN GETUTCDATE()
	                                                                                                                    ELSE @UtcEndDateTime
            END AS UtcEndDateTime
  )
  ,StartDate
  AS
  ( 
      SELECT CASE WHEN CHARINDEX('MINUTE', @DeltaTime) = 1 THEN DATEADD(MINUTE, CONVERT(INT,  REPLACE(@DeltaTime,'MINUTE','')), UtcEndDateTime)
	              WHEN CHARINDEX('HOUR',   @DeltaTime) = 1 THEN DATEADD(HOUR,   CONVERT(INT,  REPLACE(@DeltaTime,'HOUR','')),   UtcEndDateTime)
	              WHEN CHARINDEX('DAY',    @DeltaTime) = 1 THEN DATEADD(DAY,    CONVERT(INT,  REPLACE(@DeltaTime,'DAY','')),    UtcEndDateTime)
	              WHEN CHARINDEX('MONTH',  @DeltaTime) = 1 THEN DATEADD(MONTH,  CONVERT(INT,  REPLACE(@DeltaTime,'MONTH','')),  UtcEndDateTime)
	              WHEN CHARINDEX('YEAR',   @DeltaTime) = 1 THEN DATEADD(YEAR,   CONVERT(INT,  REPLACE(@DeltaTime,'YEAR','')),   UtcEndDateTime)
	              ELSE                                          DATEADD(DAY, -1,                                                UtcEndDateTime) 
				  END                               AS UtcStartDateTime
			 ,UtcEndDateTime                        AS UtcEndDateTime
      FROM EndDatetime
  )
  SELECT [UtcStartDateTime]
        ,[UtcEndDateTime]
		,CONVERT(DATETIME2(0), CONVERT(DATE, [UtcStartDateTime]))                                         AS [UtcTs_DayStartDate]
		,CONVERT(DATETIME2(0), CONVERT(DATE, [UtcEndDateTime]))                                           AS [UtcTs_DayEndDate]
		,@DefaultTimeZone                                                                                 AS [TimeZone]
		,CONVERT(DATETIME2(3), CONVERT(DATETIMEOFFSET, [UtcStartDateTime]) AT TIME ZONE @DefaultTimeZone) AS [StartDateTime]
		,CONVERT(DATETIME2(3), CONVERT(DATETIMEOFFSET, [UtcEndDateTime])   AT TIME ZONE @DefaultTimeZone) AS [EndDateTime]
  FROM StartDate
