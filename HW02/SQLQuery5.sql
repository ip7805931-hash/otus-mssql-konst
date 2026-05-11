-- Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника, который оформил заказ (SalespersonPerson). Сделать без подзапросов.

Use WideWorldImporters

SELECT TOP (10) [InvoiceID]
     ,   Sales.Invoices.InvoiceDate      
      ,FullName
      ,CustomerName
  FROM [WideWorldImporters].[Sales].[Invoices]
  left join [Sales].[Customers] on [Invoices].CustomerID = [Sales].[Customers].CustomerID
  left join [Application].[People] on SalespersonPersonID = [People].PersonID
  order by InvoiceDate desc