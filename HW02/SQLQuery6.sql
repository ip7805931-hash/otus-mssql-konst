
-- Все ид и имена клиентов и их контактные телефоны, которые покупали товар "Chocolate frogs 250g".

use [WideWorldImporters];

SELECT distinct sales_chocolate.CustomerID,
sales_chocolate.PhoneNumber,
sales_chocolate.CustomerName
from 
(SELECT   inv.[InvoiceID]
      ,inv.CustomerID,      
[PhoneNumber],
[CustomerName],
goods.StockItemName
  FROM [WideWorldImporters].[Sales].[Invoices] as inv
  left join [Sales].[Customers] as customers on inv.CustomerID = customers.CustomerID
  left join [Sales].[InvoiceLines] as lines on inv.InvoiceID = lines.InvoiceID
  left join [Warehouse].[StockItems] as goods on lines.[StockItemID] = goods.StockItemID
  where StockItemName = 'Chocolate frogs 250g') as sales_chocolate
