/*
select * from sys.database_service_objectives
*/
select
    cast(cast(end_time as datetimeoffset)at time zone 'Central European Standard Time' as datetime2(3)) as end_time
   ,avg_cpu_percent
   ,avg_data_io_percent
   ,avg_log_write_percent
   ,avg_memory_usage_percent
   ,xtp_storage_percent
   ,max_worker_percent
   ,max_session_percent
   --,dtu_limit
   --,avg_login_rate_percent
   ,avg_instance_cpu_percent
   ,avg_instance_memory_percent
   ,cpu_limit
   --,replica_role
from
    sys.dm_db_resource_stats
