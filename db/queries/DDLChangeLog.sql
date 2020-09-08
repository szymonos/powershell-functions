select
    PostTime = cast(PostTime at time zone 'Central Europe Standard Time' as datetime2(3))
   ,EventType
   ,SPID
   ,LoginName
   ,HostName
   ,ClientNetAddress
   ,SchemaName
   ,ObjectName
   ,ObjectType
   ,CommandText
   ,ProgramName
   ,TargetObjectName
   ,TargetObjectType
from
    dbo.DDLChangeLog
where
    1 = 1
    --and ObjectName like '%V3PriceListGetItemOptions%'
    --and HostName not in ('PL-W012182')
    --and LoginName = 'sqldpa_svc'
order by
    PostTime desc
