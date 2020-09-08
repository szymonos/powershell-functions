select
    databasepropertyex(db_name(), 'Updateability') as Updateability
   ,session_id
   ,db_name(database_id) as db_name
   ,login_time
   ,host_name
   ,program_name
   ,host_process_id
   ,login_name
   ,status
   ,last_request_start_time
   ,last_request_end_time
from
    sys.dm_exec_sessions
where
    session_id > 50
