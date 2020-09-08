select
    servername = serverproperty('ServerName')
   ,dbname = db_name()
   ,o.name
   ,o.schema_id
   ,o.type
   ,o.type_desc
from
    sys.objects as o
where
    o.is_ms_shipped = 0
