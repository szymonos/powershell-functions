/*
Check ExceptionText
*/

select top (100)
    Id
   ,cast(cast(EntryDate as datetimeoffset) at time zone 'Central Europe Standard Time' as datetime2(0)) as EntryDate
   ,Login
   ,ClientId
   ,OwnerId
   ,SiteType
   ,Context
   ,Page
   ,QueryString
   ,Form
   ,ExceptionText
   ,UserAgent
   ,UserHostAddress
   ,UserHostName
   ,UrlReferrer
   ,ExceptionSource
   ,StackTrace
   ,Params
from
    dbo.BLAuditErrorsLog
where
    1 = 1
    and ExceptionSource = '.Net SqlClient Data Provider'

/*
#0)Exception of type 'System.Web.HttpUnhandledException' was thrown.
#1)An invalid request URI was provided. The request URI must either be an absolute URI or BaseAddress must be set.
#0)Exception of type 'System.Web.HttpUnhandledException' was thrown.
#1)An invalid request URI was provided. The request URI must either be an absolute URI or BaseAddress must be set.
#0)Exception of type 'System.Web.HttpUnhandledException' was thrown.
#1)An invalid request URI was provided. The request URI must either be an absolute URI or BaseAddress must be set.
#0)Exception of type 'System.Web.HttpUnhandledException' was thrown.
#1)An invalid request URI was provided. The request URI must either be an absolute URI or BaseAddress must be set.
#0)Exception of type 'System.Web.HttpUnhandledException' was thrown.
#1)An invalid request URI was provided. The request URI must either be an absolute URI or BaseAddress must be set.


*/
