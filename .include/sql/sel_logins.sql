select
    l.principal_id
   , l.name
   , l.type
   , l.type_desc
   , l.is_disabled
from
    sys.sql_logins as l
