select
    database_id
   , name
   , create_date
   , compatibility_level
   , collation_name
   , state_desc
from
    sys.databases
where
    database_id > 4
    and state = 0;
