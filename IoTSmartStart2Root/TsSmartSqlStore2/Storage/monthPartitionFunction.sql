﻿CREATE PARTITION FUNCTION [monthPartitionFunction](DATETIME2(0))
    AS RANGE RIGHT
    FOR VALUES ('1900.01.01');
