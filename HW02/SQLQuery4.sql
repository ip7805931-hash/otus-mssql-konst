-- Заказы поставщикам (Purchasing.Suppliers), которые должны быть исполнены (ExpectedDeliveryDate)
-- в январе 2013 года с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName) и которые исполнены (IsOrderFinalized).

Use WideWorldImporters;

SELECT  Orders.[PurchaseOrderID]
      ,Orders.[SupplierID]
      ,Orders.[OrderDate]
      ,Orders.[DeliveryMethodID],
      ExpectedDeliveryDate,
      [IsOrderFinalized],
[DeliveryMethodName]
  FROM [WideWorldImporters].[Purchasing].[PurchaseOrders] as Orders  
  left join [Application].[DeliveryMethods] on Orders.DeliveryMethodID  = [Application].[DeliveryMethods].DeliveryMethodID
  where (Orders.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31')
  and ([IsOrderFinalized] = 1) 
  and ([DeliveryMethodName] = 'Air Freight' OR [DeliveryMethodName] = 'Refrigerated Air Freight')