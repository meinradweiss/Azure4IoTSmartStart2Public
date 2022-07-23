﻿CREATE VIEW [Mart].[TsDay]
AS

SELECT *
      ,CASE WHEN [Ts_Date] = CONVERT(DATE, GETDATE()) THEN 'Y' 
	                                                  ELSE 'N'
       END AS Today
      ,CASE WHEN [Ts_Date] > CONVERT(DATE, DATEADD(DAY, -7, GETDATE())) THEN 'Y' 
	                                                                    ELSE 'N'
       END AS LastSevenDays
      ,CASE WHEN [Ts_Date] > CONVERT(DATE, DATEADD(DAY, -30, GETDATE())) THEN 'Y' 
	                                                                     ELSE 'N'
       END AS LastThirtyDays
FROM [Core].[TsDay]
WHERE Ts_Date <= GETDATE()