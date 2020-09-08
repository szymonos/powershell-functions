declare
    @tablename sysname = 'dbo.BLTopOwnersAddresses'
   ,@colname sysname = 'PhoneNumber'
   ,@showvalues bit = 1 -- controls whether to display column values
   ,@objid nvarchar(10)
   ,@sqlcmd nvarchar(max);

set @objid = cast(object_id(@tablename) as nvarchar(10));
set @sqlcmd = N'select distinct
    columnproperty(' + @objid + N', ' + quotename(@colname, '''') + N', ''AllowsNull'') as AllowsNull' + iif(@showvalues = 1, N',' + @colname, N'')
              + N'
   ,len(' + @colname + N') as ColumnLen
   ,count(isnull(len(' + @colname + N'), 0)) as Count
from ' + @tablename + N'
group by ' + iif(@showvalues = 1, @colname + N', ', N'') + N'len(' + @colname + N')'

print @sqlcmd
exec sys.sp_executesql @stmt = @sqlcmd
