select
    SQLServerName = serverproperty('ServerName')
   ,ServerVersion = case
                        when charindex('-', @@VERSION) < charindex('(', @@VERSION) then left(@@version, charindex('-', @@version) - 2)
                        else left(@@version, charindex('(', @@version) - 2)end
   ,ProductLevel = serverproperty('ProductLevel')
   ,ProductVersion = serverproperty('ProductVersion')
   ,ServerEdition = serverproperty('Edition');

with rs
as (
   select
       convert(char(16), start_time, 120) as start_time
      ,convert(char(16), end_time, 120) as end_time
      ,database_name
      ,sku
      ,storage_in_megabytes
      ,allocated_storage_in_megabytes
      ,avg_cpu_percent
      ,avg_data_io_percent
      ,avg_log_write_percent
      ,max_worker_percent
      ,max_session_percent
      --,xtp_storage_percent
      ,avg_instance_cpu_percent
      ,avg_instance_memory_percent
      ,cpu_limit
      ,rn = row_number() over (partition by database_name order by start_time desc)
   from
       sys.resource_stats
   )
select * from rs where rn = 1;
