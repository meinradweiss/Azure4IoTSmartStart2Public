CREATE SECURITY POLICY [Security].[SignalFilter]
    ADD FILTER PREDICATE [Security].[fn_SignalSecurityPredicate]([SignalId]) ON [Core].[Signal]
    WITH (STATE = OFF);

