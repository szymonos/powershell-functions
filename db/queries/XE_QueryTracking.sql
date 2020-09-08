/*
alter event session QueryTracking on database state = start;
alter event session QueryTracking on database state = stop;
*/
set nocount on;

declare
    @target_xml xml
   ,@msg varchar(50);

set @msg = formatmessage('%s: query extended event session', convert(char(12), sysdatetimeoffset()at time zone 'Central Europe Standard Time', 114));

raiserror(@msg, 0, 1) with nowait;

select
    @target_xml = cast(t.target_data as xml)
from
    sys.dm_xe_database_sessions as s
    join sys.dm_xe_database_session_targets as t
        on t.event_session_address = s.address and t.target_name = 'ring_buffer'
where
    s.name = N'QueryTracking';

/*
select
    event_data = qp.query('.')
from
    @target_xml.nodes('RingBufferTarget/event') as q(qp);
*/
set @msg = formatmessage('%s: save results into temp table', convert(char(12), sysdatetimeoffset()at time zone 'Central Europe Standard Time', 114));

raiserror(@msg, 0, 1) with nowait;

drop table if exists #xe;

select
    timestamp = cast(xed.event_data.value('@timestamp', 'datetimeoffset(3)')at time zone 'Central Europe Standard Time' as datetime2(3))
   ,event_name = xed.event_data.value('@name', 'nvarchar(128)')
   ,spid = xed.event_data.value('(action[@name="session_id"]/value)[1]', 'int')
   ,cpu_time = cast(isnull(xed.event_data.value('(data[@name="cpu_time"]/value)[1]', 'decimal(28, 0)'), 0) / 1000000.0 as decimal(25, 3))
   ,duration = cast(isnull(xed.event_data.value('(data[@name="duration"]/value)[1]', 'decimal(28, 0)'), 0) / 1000000.0 as decimal(25, 3))
   ,sql_statement = coalesce(
                        xed.event_data.value('(data[@name="batch_text"]/value)[1]', 'varchar(max)')
                       ,xed.event_data.value('(data[@name="statement"]/value)[1]', 'varchar(max)')
                       ,xed.event_data.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)'))
   ,plan_handle = '0x' + xed.event_data.value('(action[@name="plan_handle"]/value)[1]', 'nvarchar(max)')
   ,username = xed.event_data.value('(action[@name="username"]/value)[1]', 'nvarchar(128)')
   ,client_hostname = xed.event_data.value('(action[@name="client_hostname"]/value)[1]', 'nvarchar(128)')
   ,client_app_name = xed.event_data.value('(action[@name="client_app_name"]/value)[1]', 'nvarchar(128)')
   ,physical_reads = xed.event_data.value('(data[@name="physical_reads"]/value)[1]', 'int')
   ,logical_reads = xed.event_data.value('(data[@name="logical_reads"]/value)[1]', 'int')
   ,writes = xed.event_data.value('(data[@name="writes"]/value)[1]', 'int')
   ,row_count = xed.event_data.value('(data[@name="row_count"]/value)[1]', 'int')
into
    #xe
from
    @target_xml.nodes('/RingBufferTarget/event') as xed(event_data)

set @msg = formatmessage('%s: show results', convert(char(12), sysdatetimeoffset()at time zone 'Central Europe Standard Time', 114));

raiserror(@msg, 0, 1) with nowait;

select
    timestamp
   ,event_name
   ,spid
   ,cpu_time
   ,duration
   ,sql_statement
   ,qp.query_plan
   ,username
   ,client_hostname
   ,client_app_name
   ,physical_reads
   ,logical_reads
   ,writes
   ,row_count
from
    #xe
    outer apply sys.dm_exec_query_plan(convert(varbinary(64), plan_handle, 1)) as qp
where
    1 = 1 --
    --and event_name in ('rpc_completed', 'sql_batch_completed') --
    and sql_statement <> 'exec sp_reset_connection' --
    --and duration > 0.2 --
    and client_app_name <> 'Core .Net SqlClient Data Provider' --
--and event_name = 'sql_statement_completed'
--and client_hostname not in ('ABCSQLMON', 'MUSCIMOL')
--and sql_statement like '%v3pricelistdeals%'
order by
    timestamp desc
--duration desc
