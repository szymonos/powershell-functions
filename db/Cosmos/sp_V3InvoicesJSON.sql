use XLINK;
go

if not exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'V3InvoicesJSON')
    exec ('create proc dbo.V3InvoicesJSON as select ''stub version, to be replaced''')
go

alter proc dbo.V3InvoicesJSON (@startdate datetime, @enddate datetime)
as
select-- top(1000)
    HoldingId = '10'
   ,OwnerId = case i.OwnerId
                  when '10' then '5410'
                  when '25' then '5845'
                  when '80' then '5310'
                  when '60' then '5840'
                  when '40' then '5850'
                  when '90' then '8560'
                  when '25' then '5845'
                  when '50' then '50'
                  when '30' then '30'
                  else '5410' end
   ,IID = ltrim(rtrim(i.IID))
   ,CID = ltrim(rtrim(i.CID))
   ,Delivery = left(ltrim(rtrim(i.CID)), 7) + i.Delivery
   ,OrderNo = ltrim(rtrim(i.OrderNo))
   ,Date = convert(varchar(8), i.Date, 112)
   ,i.Total
   ,i.TotalVAT
   ,i.Type
   ,i.InvoiceCurrencyId
   ,i.PaymentDays
   ,i.PaymentMethod
   ,i.CurrencyRate
   ,LastUpdate = convert(varchar(8), i.LastUpdate, 112)
   ,Lines =
        (select top 100
             OID = ltrim(rtrim(i.OID))
            ,PID = ltrim(rtrim(il.PID))
            ,il.Qty
            ,il.Price
            ,il.Value
            ,il.ValueVAT
            ,il.OrderLine
            ,il.ProductType
            ,il.ParentLNr
            ,il.StockNo
            ,ProductName = null
         from
             dbo.V3InvoicesLines as il
         where
             i.OwnerId = il.OwnerId and i.CID = il.CID and i.IID = il.IID
        for json path)
from
    dbo.V3Invoices as i
where
	i.Date between @startdate and @enddate
--for json path
go
