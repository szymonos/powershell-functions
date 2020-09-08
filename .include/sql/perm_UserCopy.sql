set nocount on;

declare
    @OldUser sysname
   ,@NewUser sysname
   ,@linebreak char(2) = char(13) + char(10)
   ,@sqltext nvarchar(max);

set @OldUser = 'ecomdf_svc'; ---- OLD User
set @NewUser = @OldUser;

---- New User
--set @NewUser = 'az_migration' ---- New User
select
    @sqltext = N'create login ' + quotename(@NewUser)collate database_default + N' with password=N''password''' + @linebreak + N'go' + @linebreak;

select
    @sqltext += N'create user ' + quotename(@NewUser)collate database_default + N' for login ' + quotename(@NewUser)collate database_default + N'
go
';

select
    @sqltext += N'ALTER USER ' + @NewUser collate database_default + N' WITH LOGIN = ' + @NewUser collate database_default + N'
go
';

select
    @sqltext += case when perm.state <> 'W' then perm.state_desc else 'grant' end + space(1) + perm.permission_name + space(1) + N'to' + space(1)
                + quotename(@NewUser)collate database_default + case
                                                                    when perm.state <> 'W' then space(0)
                                                                    else space(1) + 'with grant option' end + N'
go
'
from
    sys.database_permissions as perm
    inner join sys.database_principals as usr
        on perm.grantee_principal_id = usr.principal_id
where
    usr.name = @OldUser and perm.class <> 1 and perm.major_id = 0
order by
    perm.permission_name asc
   ,perm.state_desc asc;

select
    @sqltext += N'exec sp_addrolemember @rolename =' + space(1) + quotename(user_name(rm.role_principal_id), '''') + N', @membername =' + space(1)
                + quotename(@NewUser, '''') + N'
go
'
from
    sys.database_role_members as rm
where
    user_name(rm.member_principal_id) = @OldUser
order by
    rm.role_principal_id asc;

print @sqltext;

with perms
as (
	select
		[--Object Level Permissions] = v.a
	   ,state_desc = v.b
	   ,permission_name = v.c
	   ,class_desc = v.d
	   ,[schema] = v.e
	   ,objname = v.f
	   ,sort = v.f
	from
		(values (N'use [' + db_name() + N'];', null, null, null, null, null, 0)
			,(N'if not exists (select 1 from sys.database_principals as p where p.name = N''' + @NewUser + N''')', null, null, null, null, null, 1)
			,(N'create user ' + quotename(@OldUser) + N' for login ' + quotename(@OldUser), null, null, null, null, null, 2)
			,(N'else alter user ' + quotename(@OldUser) + N' with login = ' + quotename(@OldUser) + N';', null, null, null, null, null, 3)
		) as v (a, b, c, d, e, f, g)
   union all
   select
       [--Object Level Permissions] = 'exec sp_addrolemember @rolename =' + space(1) + quotename(user_name(rm.role_principal_id), '''') + ', @membername ='
                                      + space(1) + quotename(@NewUser, '''') + ';'
      ,state_desc = 'GRANT'
      ,permission_name = 'ROLE'
      ,class_desc = 'DATABASE'
      ,[schema] = null
      ,objname = user_name(rm.role_principal_id)
      ,sort = 4
   from
       sys.database_role_members as rm
   where
       user_name(rm.member_principal_id) = @OldUser
   union all
   select
       [--Object Level Permissions] = case when perm.state <> 'W' then perm.state_desc else 'GRANT' end + space(1) + perm.permission_name
                                      + case when perm.class <> 0 then +space(1) + 'ON' + space(1)else '' end
                                      + case when perm.class not in (0, 1, 4) then perm.class_desc + '::' else '' end
                                      + case
                                            when perm.class in (1, 6) then quotename(schema_name(isnull(obj.schema_id, typ.schema_id))) + '.'
                                            --                                         else '' end + quotename(coalesce(obj.name, sch.name, princ.name, typ.name, null))
                                            else '' end
                                      + case
                                            when perm.class <> 0 then
                                                 quotename(coalesce(obj.name, sch.name, princ.name, typ.name, 'id:' + cast(perm.major_id as varchar(2))))
                                            else '' end + case when cl.column_id is null then '' else '(' + quotename(cl.name) + ')' end + space(1) + 'TO'
                                      + space(1) + quotename(@NewUser)collate database_default + case
                                                                                                     when perm.state <> 'W' then space(0)
                                                                                                     else space(1) + 'with grant option' end + ';'
      ,perm.state_desc
      ,perm.permission_name
      ,perm.class_desc
      ,[schema] = schema_name(coalesce(obj.schema_id, typ.schema_id, sch.schema_id))
      ,objname = coalesce(obj.name, typ.name, princ.name)
      ,sort = 5
   from
       sys.database_permissions as perm
       inner join sys.database_principals as usr
           on usr.name = @OldUser and perm.grantee_principal_id = usr.principal_id
       left outer join sys.objects as obj
           on perm.class = 1 and perm.major_id = obj.object_id
       left outer join sys.schemas as sch
           on perm.class = 3 and perm.major_id = sch.schema_id
       left outer join sys.database_principals as princ
           on perm.class = 4 and perm.major_id = princ.principal_id
       left outer join sys.types as typ
           on perm.class = 6 and perm.major_id = typ.user_type_id
       left join sys.columns as cl
           on cl.object_id = perm.major_id and cl.column_id = perm.minor_id
   )
select
    perms.[--Object Level Permissions]
   ,perms.state_desc
   ,perms.permission_name
   ,perms.class_desc
   ,perms.[schema]
   ,perms.objname
from
    perms
where
    1 = 1
	--and perms.objname = 'LvsExport_ParentWaybillsToSendGet'
order by
    sort
   ,[schema]
   ,objname;
go
