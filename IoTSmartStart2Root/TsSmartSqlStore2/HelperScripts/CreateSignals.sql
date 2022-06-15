with signals
as
(
select top 1300 ROW_NUMBER() over ( order by a.OBJECT_ID) as signal_id
  from sys.objects a cross join sys.objects b
)
insert into [Core].[Signal]
([SignalId], [SignalName], [Unit])
select signal_id as SignalId
     , concat('Signal ', convert(varchar, signal_id)) as SignalName
	 ,'undefined' as unit
from signals
where not exists (select 'x' from [Core].[Signal] where [Signal].[SignalId] = signals.signal_id)

-- Split Partitions

DECLARE @RC                int
DECLARE @partitionBaseName sysname  = 'dayPartition'
DECLARE @dayAheadNumber    int      
DECLARE @startDate         datetime = convert(datetime, '2019-09-01',120)

select @dayAheadNumber = datediff(day, @startDate, getdate()) + 30


-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[SplitPartitionInDayJunks] 
   @partitionBaseName
  ,@dayAheadNumber
  ,@startDate
GO

--------------------------------

DECLARE @RC                int
DECLARE @partitionBaseName sysname  = 'monthPartition'
DECLARE @dayAheadNumber    int      
DECLARE @startDate         datetime = convert(datetime, '2019-09-01',120)

select @dayAheadNumber = datediff(day, @startDate, getdate()) + 30


-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[SplitPartitionInMonthJunks] 
   @partitionBaseName
  ,@dayAheadNumber
  ,@startDate
GO


--------------------------------


-- Grant access to Synapse Pipeline

create user mewsynapse from external provider
go

EXEC sp_addrolemember 'db_datareader', mewsynapse
go
EXEC sp_addrolemember 'db_datawriter', mewsynapse
go
