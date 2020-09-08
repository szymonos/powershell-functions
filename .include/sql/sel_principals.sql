select
    p.principal_id
   ,p.name
   ,p.type
   ,p.type_desc
   ,p.authentication_type
   ,p.authentication_type_desc
   ,p.create_date
from
    sys.database_principals as p
where
    p.principal_id > 4
