-- Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).

SELECT  S.[SupplierID]
      ,[SupplierName],      
      OrderDate
  FROM [WideWorldImporters].[Purchasing].[Suppliers] as S
  left join Purchasing.PurchaseOrders as Orders on S.SupplierID  = Orders.SupplierID 
  where OrderDate is null
