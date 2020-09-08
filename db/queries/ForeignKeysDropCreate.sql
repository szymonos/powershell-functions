/*
Skrypt służący do zdejmowania i zak�adania kluczy obcych w tabeli.
Skrypty dropuj�ce i zak�adaj�ce klucze zapisywane s� w tabeli tymczasowej
*/

declare
    @check bit = 1  -- select statements instead of execute
   ,@isDrop bit = 1 -- 1: drop FKs, 0: create FKs
   ,@fkExists bit = 0
   ,@fkname sysname
   ,@dropStmnt nvarchar(max)
   ,@createStmnt nvarchar(max);

if exists (select object_id from sys.foreign_keys) and @isDrop = 1
    drop table if exists #fktmp;

if not exists (select * from tempdb.sys.tables where name like '#fktmp%')
begin
    select
        TableName = cs.name + N'.' + ct.name
       ,ForeignKey = fk.name
       ,DropFK = N'alter table ' + quotename(cs.name) + N'.' + quotename(ct.name) + N' drop constraint ' + quotename(fk.name) + N';'
       ,CreateFK = N'alter table ' + quotename(cs.name) + N'.' + quotename(ct.name) + N' with check add constraint ' + quotename(fk.name) + N' foreign key ('
                   + stuff((select
                                ',' + quotename(c.name)
                            -- get all the columns in the constraint table
                            from
                                sys.columns as c
                                inner join sys.foreign_key_columns as fkc
                                    on fkc.parent_column_id = c.column_id and fkc.parent_object_id = c.object_id
                            where
                                fkc.constraint_object_id = fk.object_id
                            order by
                                fkc.constraint_column_id
                           for xml path(N''), type).value(N'.[1]', N'nvarchar(max)'), 1, 1, N'') + N') references ' + quotename(rs.name) + N'.'
                   + quotename(rt.name) + N'(' + stuff((select
                                                            ',' + quotename(c.name)
                                                        -- get all the referenced columns
                                                        from
                                                            sys.columns as c
                                                            inner join sys.foreign_key_columns as fkc
                                                                on fkc.referenced_column_id = c.column_id and fkc.referenced_object_id = c.object_id
                                                        where
                                                            fkc.constraint_object_id = fk.object_id
                                                        order by
                                                            fkc.constraint_column_id
                                                       for xml path(N''), type).value(N'.[1]', N'nvarchar(max)'), 1, 1, N'') + N');' + 'alter table '
                   + quotename(cs.name) + '.' + quotename(ct.name) + ' check constraint ' + quotename(fk.name) + N';'
    into
        #fktmp
    from
        sys.foreign_keys as fk
        inner join sys.tables as rt -- referenced table
            on fk.referenced_object_id = rt.object_id
        inner join sys.schemas as rs
            on rt.schema_id = rs.schema_id
        inner join sys.tables as ct -- constraint table
            on fk.parent_object_id = ct.object_id
        inner join sys.schemas as cs
            on ct.schema_id = cs.schema_id
    where
        rt.is_ms_shipped = 0 and ct.is_ms_shipped = 0;
end;

if @check = 1
begin
    select
        TableName
       ,ForeignKey
       ,DropFK
       ,CreateFK
    from
        #fktmp
    order by
        TableName
       ,ForeignKey;
--select
--    TableName = ps.name + N'.' + pt.name
--   ,ReferencedTable = rs.name + N'.' + rt.name
--   ,ForeignKey = fk.name
--from
--    sys.foreign_keys as fk
--    inner join sys.tables as pt
--        on pt.object_id = fk.parent_object_id
--    inner join sys.schemas as ps
--        on ps.schema_id = pt.schema_id
--    inner join sys.tables as rt
--        on rt.object_id = fk.referenced_object_id
--    inner join sys.schemas as rs
--        on rs.schema_id = rt.schema_id
--order by
--    ps.name
--   ,pt.name
--   ,fk.name;
end;
else
begin
    declare csr cursor local fast_forward for
    select ForeignKey, DropFK, CreateFK from #fktmp;

    open csr;

    fetch next from csr
    into
        @fkname
       ,@dropStmnt
       ,@createStmnt;

    /* Create user in database and add user to role */
    while @@fetch_status = 0
    begin
        begin try
            if exists (select object_id from sys.foreign_keys where name = @fkname)
                set @fkExists = 1;

            if @isDrop = 1 and @fkExists = 1 execute sys.sp_executesql @dropStmnt;
            else if @isDrop = 0 and @fkExists = 0 exec sys.sp_executesql @createStmnt;
        end try
        begin catch
            select serverproperty('ServerName'), error_message();
        end catch;

        fetch next from csr
        into
            @fkname
           ,@dropStmnt
           ,@createStmnt;
    end;

    close csr;
    deallocate csr;
end;
