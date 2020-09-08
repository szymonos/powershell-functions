set nocount on;

declare
    @OldUser sysname
   ,@NewUser sysname
   ,@linebreak char(2) = char(13) + char(10)
   ,@sqltext nvarchar(max);

set @OldUser = 'blservice'; -- old user
set @NewUser = 'blservice'; -- new user

select
    @sqltext = formatmessage('create login [%s] with password=N''password''%sgo%s', @NewUser, @linebreak, @linebreak)
   ,@sqltext += formatmessage('if not exists (select 1 from sys.database_principals where name = N%s)%s', quotename(@NewUser, ''''), @linebreak)
   ,@sqltext += formatmessage('create user [%s] for login [%s]%selse%s', @NewUser, @NewUser, @linebreak, @linebreak)
   ,@sqltext += formatmessage('alter user [%s] with login = [%s]%sgo%s', @NewUser, @NewUser, @linebreak, @linebreak);

select
    @sqltext += formatmessage(
                    '%s %s to [%s]%s%sgo%s', iif(perm.state <> 'W', perm.state_desc, 'grant'), perm.permission_name, @NewUser
                   ,iif(perm.state <> 'W', '', ' with grant option'), @linebreak, @linebreak)
from
    sys.database_permissions as perm
    inner join sys.database_principals as usr
        on perm.grantee_principal_id = usr.principal_id
where
    usr.name = @OldUser and perm.class <> 1 and perm.major_id = 0 and perm.type <> 'CO'
order by
    perm.permission_name asc
   ,perm.state_desc asc;

select
    @sqltext += formatmessage('alter role [%s] add member [%s]%sgo%s', user_name(rm.role_principal_id), @NewUser, @linebreak, @linebreak)
from
    sys.database_role_members as rm
where
    user_name(rm.member_principal_id) = @OldUser
order by
    rm.role_principal_id asc;

raiserror(@sqltext, 0, 1) with nowait;

with perms
as (
   select
       [--Object Level Permissions] = v.a
      ,state_desc = v.b
      ,permission_name = v.c
      ,class_desc = v.d
      ,[schema] = v.e
      ,objname = v.f
      ,sort = v.g
   from
       (values (N'use [' + db_name() + N'];', null, null, null, null, null, 0)
           ,(N'if not exists (select 1 from sys.database_principals as p where p.name = N' + quotename(@NewUser, '''') + N')', null, null, null, null, null, 1)
           ,(N'create user ' + quotename(@NewUser) + N' for login ' + quotename(@NewUser), null, null, null, null, null, 2)
           ,(N'else alter user ' + quotename(@NewUser) + N' with login = ' + quotename(@NewUser) + N';', null, null, null, null, null, 3)) as v (a, b, c, d, e
  ,f, g)
   union all
   select
       [--Object Level Permissions] = formatmessage('alter role [%s] add member [%s];%sgo%s', user_name(rm.role_principal_id), @NewUser, @linebreak, @linebreak)
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
       [--Object Level Permissions] = formatmessage(
                                          '%s %s%s%s%s%s%s TO [%s]%s;', iif(perm.state <> 'W', perm.state_desc, 'GRANT'), perm.permission_name
                                         ,iif(perm.class <> 0, ' ON ', ''), iif(perm.class not in (0, 1, 4), perm.class_desc + '::', '')
                                         ,iif(perm.class in (1, 6), quotename(schema_name(isnull(obj.schema_id, typ.schema_id))) + '.', '')
                                         ,iif(perm.class <> 0
                                          ,quotename(coalesce(obj.name, sch.name, princ.name, typ.name, 'id:' + cast(perm.major_id as varchar(2))))
                                          ,''), iif(cl.column_id is not null, '(' + quotename(cl.name) + ')', ''), @NewUser
                                         ,iif(perm.state <> 'W', '', ' with grant option'))
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
   where
       perm.type <> 'CO'
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
order by
    perms.sort
   ,perms.class_desc
   ,perms.permission_name
   ,perms.[schema]
   ,perms.objname;
go
/*
select
    perm.major_id
   ,perm.state_desc
   ,perm.permission_name
   ,perm.minor_id
   ,perm.class_desc
   ,typ.name
   ,tsch.name
from
    sys.database_principals as usr
    inner join sys.database_permissions as perm
        on perm.grantee_principal_id = usr.principal_id
    left outer join sys.types as typ
        on perm.class = 6 and perm.major_id = typ.user_type_id
    left outer join sys.schemas as tsch
        on tsch.schema_id = typ.schema_id
where
    usr.name = 'solp_user' and perm.class = 6;
*/
