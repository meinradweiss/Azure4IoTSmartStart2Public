CREATE PARTITION SCHEME [monthPartitionScheme]
    AS PARTITION [monthPartitionFunction]
    TO ([PRIMARY], [PRIMARY]);

