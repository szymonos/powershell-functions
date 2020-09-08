drop table if exists #xerr;
go

select -- distinct
    error_number
   --   ,error_cnt = count(*)
   ,timestamp
   ,message
   ,sql_text
   ,stack_statement
   ,stack_line
   ,username
   ,client_hostname
   ,client_app_name
into
    #xerr
from
    --dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-ac')
    --dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-docs')
    --dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-ecomtb')
    --dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-edi')
    --dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-lang')
    --dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-ldhesd')
    --dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-rma')
    --dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-scm')
    --dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-solp')
    dbo.fn_XEErrorInfoReader('https://alsoilprodsqlstorage.blob.core.windows.net/extended-events/error-xlink')
where
    1 = 1 --
    and username not in ('calineczka', 'sa', 'NT AUTHORITY\SYSTEM')
    and error_number not in (9104, 156, 229, 245, 50000) -- "auto statistics internal": used internally for control flow
    --and timestamp > '20200625'
go

select
    error_number
   ,timestamp
   ,message
   ,sql_text
   ,stack_statement
   ,stack_line
   ,username
   ,client_hostname
   ,client_app_name
from
    #xerr
where
    1 = 1
    and username not like '%@also.com'
    --and (stack_statement like '%ElasticProduct%' or sql_text like '%ElasticProduct%')
    --and stack_statement like '%TypeHierarchyFlatCombined%'
order by
    timestamp desc
