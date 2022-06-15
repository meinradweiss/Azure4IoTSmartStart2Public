

CREATE FUNCTION [Security].[fn_SignalSecurityPredicate](@SignalId AS int)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_SignalSecurityPredicate_result
WHERE @SignalId in 
(
-- REGULAR USER VIA DIRECT CONNECTION, e.g. (PowerBI, Excel, SQL Server management studio, ...)
--   Returns SignalIds assigned to role of user as defined in ApplicationRoleSignalAccess (intersection table Security.ApplicationRole <-> Core.Signal). 
--   Returns nothing if role is applicationAdmin since applicationAdmin has no SignalIds assigned in ApplicationRoleSignalAccess
  SELECT [SignalId] 
  FROM [Security].[ApplicationRoleSignalAccess]
	INNER JOIN [Security].[ApplicationRoleMember]
	 ON [ApplicationRoleSignalAccess].[RoleId] = [ApplicationRoleMember].[RoleId]
  WHERE [ApplicationRoleMember].[UserId] = SYSTEM_USER 
    AND SYSTEM_USER <> 'temporarydevdashlogin'
	AND SYSTEM_USER <> 'MiddleTierApiLogin'

UNION ALL
-- REGULAR USER VIA MIDDLE TIER (e.g. frontend hydro insights, API)
--   Ensure that users accessing the database via a middle_tier (e.g. frontend) can only access their granted Signals 
  SELECT [SignalId] 
  FROM [Security].[ApplicationRoleSignalAccess]
	INNER JOIN [Security].[ApplicationRoleMember]
	 ON [ApplicationRoleSignalAccess].[RoleId] = [ApplicationRoleMember].[RoleId]
  WHERE [ApplicationRoleMember].[UserId] = CONVERT(sysname, SESSION_CONTEXT(N'UserId_connected_through_middle_tier'))
    AND (SYSTEM_USER = 'temporarydevdashlogin' OR SYSTEM_USER = 'MiddleTierApiLogin')

UNION ALL
-- ADMIN USER
--   Returns all SignalIds if user is applicationAdmin
  SELECT [SignalId] as [SignalId] 
  FROM [Core].[Signal]
  WHERE EXISTS (SELECT 'x' from [Security].[ApplicationRoleMember] WHERE [RoleId] = 'ApplicationAdmin' AND [UserId] = SYSTEM_USER)
)