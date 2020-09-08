drop table if exists #xed;
go

with xed (event_data)
as (
   select
       event_data = cast(event_data as xml)
   from
       sys.fn_xe_file_target_read_file('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/rma-lrq', null, null, null)
       --sys.fn_xe_file_target_read_file('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/xlink-lrq', null, null, null)
   )
select
    timestamp = cast(xed.event_data.value('(//event/@timestamp)[1]', 'datetimeoffset(3)')at time zone 'Central Europe Standard Time' as datetime2(3))
   ,event_name = xed.event_data.value('(//event/@name)[1]', 'varchar(50)')
   ,spid = xed.event_data.value('(//event/action[@name="session_id"]/value)[1]', 'int')
   ,cpu_time = isnull(xed.event_data.value('(//event/data[@name="cpu_time"]/value)[1]', 'bigint'), 0) / 1000
   ,duration = isnull(xed.event_data.value('(//event/data[@name="duration"]/value)[1]', 'bigint'), 0) / 1000
   ,statement = isnull(
                    xed.event_data.value('(//event/data[@name="statement"]/value)[1]', 'nvarchar(max)')
                   ,xed.event_data.value('(//event/data[@name="batch_text"]/value)[1]', 'nvarchar(max)'))
   ,sql_text = xed.event_data.value('(//event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)')
   ,object_name = xed.event_data.value('(//event/data[@name="object_name"]/value)[1]', 'nvarchar(max)')
   ,physical_reads = xed.event_data.value('(//event/data[@name="physical_reads"]/value)[1]', 'int')
   ,logical_reads = xed.event_data.value('(//event/data[@name="logical_reads"]/value)[1]', 'int')
   ,writes = xed.event_data.value('(//event/data[@name="writes"]/value)[1]', 'int')
   ,row_count = xed.event_data.value('(//event/data[@name="row_count"]/value)[1]', 'int')
   ,username = xed.event_data.value('(//event/action[@name="username"]/value)[1]', 'nvarchar(128)')
   ,client_hostname = xed.event_data.value('(//event/action[@name="client_hostname"])[1]', 'nvarchar(128)')
   ,client_app_name = xed.event_data.value('(//event/action[@name="client_app_name"])[1]', 'nvarchar(128)')
into
    #xed
from
    xed

select
    timestamp
   ,event_name
   ,spid
   ,cpu_time = dbo.fn_ms2Time(cpu_time)
   ,duration = dbo.fn_ms2Time(duration)
   ,statement
   ,sql_text
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
    1 = 1
    and username not in ('ecomdf_svc', 'jobs_user')
    and duration > 5000
order by
    duration desc
