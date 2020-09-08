select
    DBName = db_name()
   ,DatabaseRoleName = roles.name
   ,DatabaseUserName = members.name
from
    sys.database_principals as roles
    inner join sys.database_role_members as rm
    on rm.role_principal_id = roles.principal_id
    inner join sys.database_principals as members
    on members.principal_id = rm.member_principal_id
        and members.principal_id > 4
where
    roles.type = 'R'
order by
    roles.name;
