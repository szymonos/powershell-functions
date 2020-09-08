/*
https://docs.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store
https://docs.microsoft.com/en-us/sql/relational-databases/performance/best-practice-with-the-query-store
https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-query-store-runtime-stats-transact-sql
*/

select
    qsq.query_id
   ,qsp.plan_id
   ,qsq.object_id
   ,isnull(object_schema_name(qsq.object_id) + N'.', '') + object_name(qsq.object_id) as object_name
   ,dbo.fn_ms2Time(rs.max_duration / 1000) as max_duration
   ,dbo.fn_ms2Time(rs.min_duration / 1000) as min_duration
   ,dbo.fn_ms2Time(rs.avg_duration / 1000) as avg_duration
   ,dbo.fn_ms2Time(rs.stdev_duration / 1000) as stdev_duration
   ,cast(rs.first_execution_time at time zone 'Central European Standard Time' as datetime2(0)) as first_execution_time
   ,cast(rs.last_execution_time at time zone 'Central European Standard Time' as datetime2(0)) as last_execution_time
   ,round(rs.avg_logical_io_reads, 1) as avg_logical_io_reads
   ,rs.count_executions
   ,try_convert(xml, qsp.query_plan) as query_plan
   ,qsq.query_text_id
   ,qst.query_sql_text
from
    sys.query_store_query qsq
    join sys.query_store_query_text qst
        on qsq.query_text_id = qst.query_text_id
    join sys.query_store_plan qsp
        on qsq.query_id = qsp.query_id
    join sys.query_store_runtime_stats rs
        on qsp.plan_id = rs.plan_id
where
    1 = 1 --
    --and rs.last_execution_time > dateadd(minute, -10, sysdatetime()) -- executions in last...
    and rs.last_execution_time > cast(sysdatetime() as date) -- today's executions
    and rs.max_duration between 25000000 and 35000000 -- queries that time-outed (max_duration in 25-35s)
    --and rs.min_duration between 25000000 and 35000000 -- queries that always time-outed (min_duration in 25-35s)
    --and rs.stdev_duration > 5000000 -- duration standard deviation >5s
    --and qsp.plan_id = 39445 -- search by plan
    --and qsq.query_id = 43357
    --and qsq.query_text_id = 313014 -- search by query text
    --and qst.query_sql_text like ('%ClientProductExceptions%') -- search by query text fragment
    --and qsq.object_id = object_id(N'dbo.CRApplicationInvoiceSearch') -- search by object
    and qsq.object_id > 0 -- exclude ad hoc queries (no object)
order by
    --rs.max_duration desc
    qsq.query_id
   ,rs.runtime_stats_interval_id desc
