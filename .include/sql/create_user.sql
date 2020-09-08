if not exists (select * from sys.database_principals where name = 'ci_service')
	create user ci_service for login ci_service
else
	alter user ci_service with login = ci_service
go

-- Add user to the database owner role
exec sp_addrolemember N'db_owner', N'ci_service'
go
