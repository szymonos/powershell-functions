set nocount on;

declare @target_xml xml;

select
    @target_xml = cast(t.target_data as xml)
from
    sys.dm_xe_database_sessions as s
    join sys.dm_xe_database_session_targets as t
        on t.event_session_address = s.address and t.target_name = 'ring_buffer'
where
    s.name = N'RpcBatchTracking';

drop table if exists #xed;

select
    timestamp = cast(xed.event_data.value('(@timestamp)[1]', 'datetimeoffset(3)')at time zone 'Central Europe Standard Time' as datetime2(3))
   ,event_name = xed.event_data.value('(@name)[1]', 'varchar(50)')
   ,spid = xed.event_data.value('(action[@name="session_id"]/value)[1]', 'int')
   ,cpu_time = isnull(xed.event_data.value('(data[@name="cpu_time"]/value)[1]', 'bigint'), 0) / 1000
   ,duration = isnull(xed.event_data.value('(data[@name="duration"]/value)[1]', 'bigint'), 0) / 1000
   ,statement = isnull(
                    xed.event_data.value('(data[@name="statement"]/value)[1]', 'nvarchar(max)')
                   ,xed.event_data.value('(data[@name="batch_text"]/value)[1]', 'nvarchar(max)'))
   ,sql_text = xed.event_data.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)')
   ,objectname = xed.event_data.value('(data[@name="object_name"]/value)[1]', 'nvarchar(max)')
   ,physical_reads = xed.event_data.value('(data[@name="physical_reads"]/value)[1]', 'int')
   ,logical_reads = xed.event_data.value('(data[@name="logical_reads"]/value)[1]', 'int')
   ,writes = xed.event_data.value('(data[@name="writes"]/value)[1]', 'int')
   ,row_count = xed.event_data.value('(data[@name="row_count"]/value)[1]', 'int')
   ,username = xed.event_data.value('(action[@name="username"]/value)[1]', 'nvarchar(128)')
   ,client_hostname = xed.event_data.value('(action[@name="client_hostname"])[1]', 'nvarchar(128)')
   ,client_app_name = xed.event_data.value('(action[@name="client_app_name"])[1]', 'nvarchar(128)')
into
    #xed
from
    @target_xml.nodes('/RingBufferTarget/event') as xed(event_data)

select
    timestamp
   ,event_name
   ,spid
   ,cpu_time = dbo.fn_ms2Time(cpu_time)
   ,duration = dbo.fn_ms2Time(duration)
   ,statement
   ,sql_text
   ,objectname
   ,physical_reads
   ,logical_reads
   ,writes
   ,row_count
   ,username
   ,client_hostname
   ,client_app_name
from
    #xed
where
    1 = 1 --
    --and event_name in ('rpc_completed', 'sql_batch_completed') --
    --and statement <> 'exec sp_reset_connection' --
    --and duration > 1000 --
    --and client_app_name <> 'Core .Net SqlClient Data Provider' --
    --and objectname like '%PB2AttribPartGet%'
    --and statement like '%VD1IJklEPSZQSUQ9MjA1NTUzNSZBPTEmTFA9ODM%'
    --and sql_text like '%VD1IJklEPSZQSUQ9MjA1NTUzNSZBPTEmTFA9ODM%'
    and client_hostname not in ('ABCSQLMON')
order by
    timestamp desc
