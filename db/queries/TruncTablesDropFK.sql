use [XLINK.ALSO]

set nocount on;

declare
    @check bit = 0 --print statements instead of execute
   ,@StartTable sysname --= 'dbo.GivesBatchLoad'
   ,@EndTable sysname --= 'dbo.RecsPos'
   ,@StartRow int  --= 1
   ,@EndRow int    --= 300
   ,@schema sysname
   ,@table sysname
   ,@refid int
   ,@refschema sysname
   ,@reftable sysname
   ,@fk sysname
   ,@dropcmd nvarchar(max)
   ,@sql_cmd nvarchar(max) = N'';

select
    rn = row_number() over (order by s.name, t.name)
   ,t.object_id
   ,schema_name = s.name
   ,table_name = t.name
   ,p.rows
into
    #trunctables
from
    sys.tables as t
    inner join sys.schemas as s
        on t.schema_id = s.schema_id
    inner join sys.partitions as p
        on p.object_id = t.object_id and p.index_id in (0, 1)
where
    t.is_ms_shipped = 0; --user created tables

if @StartTable is null and @StartRow is null set @StartRow = 1;
else if @StartTable is not null
    select
        @StartRow = rn
    from
        #trunctables
    where
        schema_name + N'.' + table_name = @StartTable;

if @EndTable is null and @EndRow is null
    select @EndRow = max(rn)from #trunctables;
else if @EndTable is not null
    select
        @EndRow = rn
    from
        #trunctables
    where
        schema_name + N'.' + table_name = @EndTable;

if @check = 1
begin
    select
        rn
       ,schema_name
       ,table_name
       ,rows
    from
        #trunctables
    where
        rn between @StartRow and @EndRow
	order by rows desc;
end;

begin
    declare csr cursor local fast_forward for
    select
        object_id
       ,schema_name
       ,table_name
    from
        #trunctables
    where
        rn between @StartRow and @EndRow and rows > 0;

    open csr;

    fetch next from csr
    into
        @refid
       ,@schema
       ,@table;

    while @@fetch_status = 0
    begin
        declare fkcrs cursor local fast_forward for
        select
            schema_name = quotename(s.name)
           ,table_name = quotename(t.name)
           ,fkname = quotename(k.name)
        from
            sys.foreign_keys as k
            inner join sys.tables as t
                on t.object_id = k.parent_object_id
            inner join sys.schemas as s
                on s.schema_id = t.schema_id
        where
            k.referenced_object_id = @refid;

        open fkcrs;

        fetch next from fkcrs
        into
            @refschema
           ,@reftable
           ,@fk;

        while @@fetch_status = 0
        begin
            set @dropcmd = N'alter table ' + @refschema + N'.' + @reftable + N' drop constraint ' + @fk + N';';

            begin try
                if @check = 0 exec sp_executesql @dropcmd;

                print @dropcmd;
            end try
            begin catch
                select serverproperty('ServerName'), error_message();
            end catch;

            fetch next from fkcrs
            into
                @refschema
               ,@reftable
               ,@fk;
        end;

        close fkcrs;
        deallocate fkcrs;

        set @sql_cmd = N'truncate table ' + quotename(@schema) + N'.' + quotename(@table) + N';';

        begin try
            if @check = 0 exec sp_executesql @sql_cmd;

            print @sql_cmd;
        end try
        begin catch
            select serverproperty('ServerName'), error_message();
        end catch;

        fetch next from csr
        into
            @refid
           ,@schema
           ,@table;
    end;

    close csr;
    deallocate csr;
end;

drop table if exists #trunctables;
