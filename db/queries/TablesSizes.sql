/*
Skrypt monitoruj�cy rozmiary wybranego zakresu tabel
*/

declare
    @StartTable sysname = 'dbo.V3InvoicesLines'
   ,@EndTable sysname = 'dbo.V3InvoicesLines'
   ,@StartRow int --= 1
   ,@EndRow int;  --= 300

select
    table_id = t.object_id
   ,table_name = s.name + N'.' + t.name
   ,rn = row_number() over (order by s.name, t.name)
into
    #tb
from
    sys.tables as t
    inner join sys.schemas as s
        on s.schema_id = t.schema_id;

if @StartTable is null and @StartRow is null set @StartRow = 1;
else if @StartTable is not null
    select @StartRow = rn from #tb where table_name = @StartTable;

if @EndTable is null and @EndRow is null
    select @EndRow = max(rn)from #tb;
else if @EndTable is not null
    select @EndRow = rn from #tb where table_name = @EndTable;

select
    TableName = s.name + N'.' + t.name
   ,RowCounts = p.rows
   ,TotalPages = sum(a.total_pages)
   ,TotalSpaceMB = cast(round(((sum(a.total_pages) * 8) / 1024.00), 2) as decimal(18, 1))
   ,UsedSpaceMB = cast(round(((sum(a.used_pages) * 8) / 1024.00), 2) as decimal(18, 1))
   ,UnusedSpaceMB = cast(round(((sum(a.total_pages) - sum(a.used_pages)) * 8) / 1024.00, 2) as decimal(18, 1))
from
    sys.tables as t
    inner join sys.indexes as i
        on i.object_id > 255 and t.object_id = i.object_id
    inner join sys.partitions as p
        on i.object_id = p.object_id and i.index_id = p.index_id
    inner join sys.allocation_units as a
        on p.partition_id = a.container_id
    left outer join sys.schemas as s
        on t.schema_id = s.schema_id
where
    1 = 1 and t.is_ms_shipped = 0 --user created tables
    and t.object_id in (select table_id from #tb where rn between @StartRow and @EndRow)
--    and t.name in ('Invoices', 'Items', 'ItemsLangs', 'ItemsWarrantyHistories', 'Packages', 'V3InvoicesLines')
--    t.name like 'PLL%' and t.is_ms_shipped = 0 and i.object_id > 255
group by
    s.name
   ,t.name
   ,p.rows
order by
    TotalSpaceMB desc;

drop table if exists #tb;
