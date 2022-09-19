
CREATE FUNCTION [Mart].[GetRelativeTimeWindow] 
  (  @DeltaTime         VARCHAR(25)
    ,@EndDateTime_UTC   DATETIME2(3) = NULL
	,@TargetTimeZone    VARCHAR(50) = 'Central European Standard Time' 
  )
RETURNS TABLE
AS 
RETURN 


  WITH EndDatetime
  AS
  (
     -- '9999-12-31 23:59:59.999' case is for Power BI parameters 
     SELECT CASE WHEN @EndDateTime_UTC IS NULL OR @EndDateTime_UTC = CONVERT(DATETIME2(3), '9999-12-31 23:59:59',121) THEN GETUTCDATE()
	                                                                                                                  ELSE @EndDateTime_UTC
            END AS EndDateTime_UTC
  )
  ,StartDate
  AS
  ( 
      SELECT CASE WHEN CHARINDEX('SECOND', @DeltaTime) = 1 THEN DATEADD(SECOND, CONVERT(INT,  REPLACE(@DeltaTime,'SECOND','')), EndDateTime_UTC)
	              WHEN CHARINDEX('MINUTE', @DeltaTime) = 1 THEN DATEADD(MINUTE, CONVERT(INT,  REPLACE(@DeltaTime,'MINUTE','')), EndDateTime_UTC)
	              WHEN CHARINDEX('HOUR',   @DeltaTime) = 1 THEN DATEADD(HOUR,   CONVERT(INT,  REPLACE(@DeltaTime,'HOUR','')),   EndDateTime_UTC)
	              WHEN CHARINDEX('DAY',    @DeltaTime) = 1 THEN DATEADD(DAY,    CONVERT(INT,  REPLACE(@DeltaTime,'DAY','')),    EndDateTime_UTC)
	              WHEN CHARINDEX('MONTH',  @DeltaTime) = 1 THEN DATEADD(MONTH,  CONVERT(INT,  REPLACE(@DeltaTime,'MONTH','')),  EndDateTime_UTC)
	              WHEN CHARINDEX('YEAR',   @DeltaTime) = 1 THEN DATEADD(YEAR,   CONVERT(INT,  REPLACE(@DeltaTime,'YEAR','')),   EndDateTime_UTC)
	              ELSE                                          DATEADD(DAY, -1,                                                EndDateTime_UTC) 
				  END                               AS StartDateTime_UTC
			 ,EndDateTime_UTC                       AS EndDateTime_UTC
      FROM EndDatetime
  )
  SELECT [StartDateTime_UTC]
        ,[EndDateTime_UTC]
   	    ,CONVERT(INT, CONVERT(VARCHAR(30), [StartDateTime_UTC], 112))                                      AS [Ts_DayStartDate_UTC]
		,CONVERT(INT, CONVERT(VARCHAR(30), [EndDateTime_UTC], 112))                                        AS [Ts_DayEndDate_UTC]
		,@TargetTimeZone                                                                                   AS [TimeZone]
		,CONVERT(DATETIME2(3), CONVERT(DATETIMEOFFSET, [StartDateTime_UTC]) AT TIME ZONE @TargetTimeZone)  AS [StartDateTime]
		,CONVERT(DATETIME2(3), CONVERT(DATETIMEOFFSET, [EndDateTime_UTC])   AT TIME ZONE @TargetTimeZone)  AS [EndDateTime]
		,@DeltaTime                                                                                        AS [DeltaTime]
  FROM StartDate
