select c.ColumnName into #tmp from (values ('MATERIAL_NO'),('CROSS_MATERIAL_NO'),('SALESORG_NO'),('RELATION_TYPE')) as c (ColumnName);

declare
    @table_name sysname = N'dbo._crossselling'
   ,@columns varchar(100)
   ,@predicate varchar(255)
   ,@sqlcmd nvarchar(max);

select @columns = string_agg('o.' + quotename(ColumnName), ', ')from #tmp;

select
    @predicate = string_agg('d.' + quotename(ColumnName) + ' = o.' + quotename(ColumnName), ' and ')
from
    #tmp;

drop table if exists #tmp;

set @sqlcmd = N'with duplicate as
(select ' + @columns + N', rn = row_number() over (partition by ' + @columns + N' order by ' + @columns + N')
from ' + @table_name + N' as o)
select o.*, rn = row_number() over (partition by ' + @columns + N' order by ' + @columns + N')
from ' + @table_name + N' as o
inner join duplicate as d
on d.rn = 2 and ' + @predicate + N'
order by ' + @columns;

raiserror(@sqlcmd, 0, 1) with nowait;

exec sys.sp_executesql @sqlcmd;
