


CREATE FUNCTION [Mart].[GetTsDayForRelativeTimeWindow] 
  (  @DeltaTime       VARCHAR(25)
    ,@EndDateTime     DATETIME2(3) 
	,@DefaultTimeZone VARCHAR(50) = 'Central European Standard Time' 
  )
RETURNS TABLE
AS 
RETURN 



  SELECT *
      
  FROM [Core].[TsDay]
    CROSS JOIN [Mart].[GetRelativeTimeWindow] (@DeltaTime, @EndDateTime, @DefaultTimeZone)
  WHERE [Ts_Day] >= [Ts_DayStartDate_UTC] 
    AND [Ts_Day] <= [Ts_DayEndDate_UTC]