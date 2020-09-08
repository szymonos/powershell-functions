declare
    @obj sysname = N'transfers.SalesOrganisationItem'
   ,@objid int
   ,@schema sysname
   ,@name sysname
   ,@schemaid sysname;

set @objid = object_id(@obj);
set @schema = object_schema_name(@objid);
set @name = object_name(@objid);
set @schemaid = schema_id(@schema);

select
    perm.state_desc
   ,string_agg(perm.permission_name, ', ') as permission_name
   ,user_name(perm.grantee_principal_id) as grantee
   ,case perm.class
        when 0 then db_name()
        when 1 then @schema + N'.' + @name
        when 3 then @schema
        else null end as granted_obj
   ,perm.class_desc
   ,user_name(perm.grantor_principal_id) as grantor
from
    sys.database_permissions perm
where
    (perm.class = 0 and perm.type in ('AL', 'CL', 'DL', 'EX', 'IN', 'SL', 'TO', 'UP', 'VW')) --database level
    or (perm.class = 1 and perm.major_id = @objid) --object level
    or (perm.class = 3 and perm.major_id = @schemaid) --schema level
group by
    perm.state_desc
   ,perm.class
   ,perm.grantee_principal_id
   ,perm.class_desc
   ,perm.grantor_principal_id
