CREATE PARTITION SCHEME [dayPartitionScheme]
    AS PARTITION [dayPartitionFunction]
    TO ([PRIMARY], [PRIMARY]);

