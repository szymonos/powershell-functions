select
    serverproperty('ServerName') as SQLServerName
   ,serverproperty('Edition') as ServerEdition
   ,db_name() as DatabaseName
   ,databasepropertyex(db_name(), 'Updateability') as ApplicationIntent;
