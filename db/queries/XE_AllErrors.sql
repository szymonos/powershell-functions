/*
alter event session AllErrors on database state = start;
alter event session AllErrors on database state = stop;
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
    s.name = N'AllErrors';

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
--   ,event_name = xed.event_data.value('@name', 'nvarchar(128)')
--   ,spid = xed.event_data.value('(action[@name="session_id"])[1]', 'int')
   ,error_number = xed.event_data.value('(data[@name="error_number"]/value)[1]', 'int')
   ,severity = xed.event_data.value('(data[@name="severity"]/value)[1]', 'int')
   ,category = xed.event_data.value('(data[@name="category"]/text)[1]', 'nvarchar(128)')
   ,destination = xed.event_data.value('(data[@name="destination"]/text)[1]', 'nvarchar(128)')
   ,message = xed.event_data.value('(data[@name="message"]/value)[1]', 'varchar(255)')
   ,sql_text = xed.event_data.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)')
   ,username = xed.event_data.value('(action[@name="username"])[1]', 'nvarchar(128)')
   ,client_hostname = xed.event_data.value('(action[@name="client_hostname"])[1]', 'nvarchar(128)')
   ,client_app_name = xed.event_data.value('(action[@name="client_app_name"])[1]', 'nvarchar(128)')
into
    #xe
from
    @target_xml.nodes('/RingBufferTarget/event') as xed(event_data)

set @msg = formatmessage('%s: show results', convert(char(12), sysdatetimeoffset()at time zone 'Central Europe Standard Time', 114));

raiserror(@msg, 0, 1) with nowait;

select
    timestamp
--   ,event_name
--   ,spid
   ,error_number
   ,severity
   ,category
   ,destination
   ,message
   ,sql_text
   ,username
   ,client_hostname
   ,client_app_name
from
    #xe
where
    1 = 1 --
    and message <> ''
    and error_number <> 156
    --and sql_text <> 'exec sp_reset_connection' --
    --and client_hostname not in ('ABCSQLMON', 'MUSCIMOL')
order by
    timestamp desc

