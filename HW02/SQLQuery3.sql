-- аказы (Orders) с ценой товара (UnitPrice) более 100$ либо количеством единиц (Quantity) 
-- товара более 20 штуки присутствующей датой комплектации всего заказа (PickingCompletedWhen)
use WideWorldImporters;

select distinct Spec_orders.[ID]
from 
(SELECT   Orders.[OrderID] as ID,
      lines.UnitPrice,
      Lines.Quantity,
      Lines.PickingCompletedWhen
  FROM [WideWorldImporters].[Sales].[Orders] as Orders
  LEFT join Sales.OrderLines as Lines on Orders.OrderID = Lines.OrderID
  LEFt join Warehouse.StockItems as goods on Lines.StockItemID = goods.StockItemID 
  where (lines.UnitPrice > 100 
  OR Lines.Quantity > 20) 
  AND Lines.PickingCompletedWhen is not null) as Spec_orders
  
  
