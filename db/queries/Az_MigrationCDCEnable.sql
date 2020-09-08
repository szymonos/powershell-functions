use [Az-XLINK];
go

set nocount on;

declare
    @schema sysname
   ,@table sysname
   ,@sql_cmd nvarchar(max) = N''
   ,@lb char(2) = char(13) + char(10);

if exists (select 1 from sys.databases where is_cdc_enabled = 0 and name = db_name()) exec sys.sp_cdc_enable_db

declare csr cursor fast_forward for
select
    sname = s.name
   ,sname = t.name
from
    sys.tables as t
    inner join sys.schemas as s
        on t.schema_id = s.schema_id
where
    t.is_ms_shipped = 0
    and t.is_tracked_by_cdc = 0
    and t.type = 'U'
    and objectproperty(t.object_id, 'TableHasPrimaryKey') = 0

open csr

fetch next from csr
into
    @schema
   ,@table

/* Create user in database and add user to role */
while @@fetch_status = 0
begin
    set @sql_cmd = N'EXEC sys.sp_cdc_enable_table
@source_schema = N' + quotename(@schema, '''') + N',
@source_name   = N' + quotename(@table, '''') + N',
@role_name     = NULL'

    begin try
        --print @sql_cmd
        exec sp_executesql @sql_cmd
    end try
    begin catch
        select serverproperty('ServerName'), error_message()
    end catch

    fetch next from csr
    into
        @schema
       ,@table
end

close csr
deallocate csr
