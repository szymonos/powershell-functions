select
    id = OwnerId + IID
   ,HoldingId = '100'
   ,IID
   ,Type = case when Type = 'CR' then 'O' else 'M' end
   ,OwnerId = case OwnerId
                  when '10' then '5410'
                  when '25' then '5845'
                  when '50' then '5845'
                  when '40' then '5850'
                  when '60' then '5840'
                  when '80' then '5310'
                  when '90' then '5860'
                  else OwnerId end
   ,CID = rtrim(CID) + '000'
   ,Delivery = rtrim(CID) + Delivery
   ,Date
   ,Total
   ,TotalVAT
   ,InvoiceCurrencyId
   ,CurrencyRate
   ,LastUpdate
   ,OID
   ,OrderNo
   ,TotalCharges
   ,TotalBase
   ,TotalVATBase
   ,TotalChargesBase
   ,Discount
   ,DiscountBase
   ,PickId
   ,InvoiceDSQ
   ,StampChargeFlag
   ,PaymentDays
   ,PaymentMethod
   ,ElectronicInvoice
   ,ElectronicFlag
   ,CurrencyTableId
   ,ToDelete = cast(0 as bit)
   ,ArcDocId = null
from
    dbo.V3Invoices
