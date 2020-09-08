if not exists (select * from sys.sql_logins where name = 'ci_service')
	create login ci_service with password = 'pass'
go
