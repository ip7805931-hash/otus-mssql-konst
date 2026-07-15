/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

Select People.FullName, People.PersonID, People.IsSalesperson 
From Application.People AS People
WHERE 
People.IsSalesperson = 1 and
 NOT EXISTS (Select distinct [SalespersonPersonID]
from Sales.Invoices
where [InvoiceDate]  = '2015-07-04' 
AND [SalespersonPersonID] = People.PersonID)

; WITH SalesCTE as 
(Select distinct [SalespersonPersonID] as ID, [InvoiceDate]
from Sales.Invoices
where [InvoiceDate]  between '2015-07-04' and '2015-07-04')

Select People.FullName, People.PersonID, People.IsSalesperson 
From Application.People AS People
left join SalesCTE on SalesCTE.ID = People.PersonID
WHERE 
People.IsSalesperson = 1 and 
SalesCTE.ID is Null



/*
2. Выберите товары с минимальной ценой (подза просом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

select [StockItemID], [StockItemName],[UnitPrice]
from Warehouse.StockItems
inner join 
(select min (UnitPrice) as MinPrice
from Warehouse.StockItems) as Price on MinPrice = UnitPrice 

;With MinPriceCTE as (select min (UnitPrice) as MinPrice
from Warehouse.StockItems)

select [StockItemID], [StockItemName],[UnitPrice]
from Warehouse.StockItems
inner join MinPriceCTE on MinPrice = [UnitPrice]

select [StockItemID], [StockItemName],[UnitPrice]
from Warehouse.StockItems
where [UnitPrice]  <= all 
(select UnitPrice as MinPrice
from Warehouse.StockItems)  

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
; with MaxAmmountCTE as (
select top 5 TransactionAmount, [CustomerID], [CustomerTransactionID]
from
[Sales].[CustomerTransactions]
order by TransactionAmount desc)

--select * from MaxAmmountCTE

select DIstinct customers.[CustomerID], [CustomerName]
from sales.Customers as customers
inner join MaxAmmountCTE on MaxAmmountCTE.CustomerID = customers.CustomerID
 
select distinct Sales.[Customers].CustomerID as ID, [CustomerName]
from [Sales].[CustomerTransactions] as sale
inner join Sales.Customers on  Customers.[CustomerID] = sale.CustomerID
inner join (select top 5 TransactionAmount as Amount, [CustomerTransactionID]
from
[Sales].[CustomerTransactions]
order by TransactionAmount desc) as topSale on topSale.[CustomerTransactionID] = sale.[CustomerTransactionID]


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/
USE WideWorldImporters
go 

; with ExpensiveGoodsCTE as (
select distinct top 3 [UnitPrice] 
from [Sales].[InvoiceLines]
order by [UnitPrice] desc)

--select * from ExpensiveGoodsCTE


select distinct [DeliveryCityID],[CityName], inv.[PackedByPersonID],  [FullName]
from [Sales].[InvoiceLines] as lines
inner join ExpensiveGoodsCTE on lines.[UnitPrice] = ExpensiveGoodsCTE.UnitPrice
inner join  [Sales].[Invoices] as inv on lines.InvoiceID = inv.InvoiceID
left join [Sales].[Customers] as [Customers] on inv.CustomerID = Customers.[CustomerID]
left join Application.Cities as Cities on [Customers].[DeliveryCityID]  = Cities.CityID
left join Application.People as people on people.[PersonID] = inv.[PackedByPersonID]

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

USE WideWorldImporters
SET STATISTICS IO, TIME ON

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

/*запрос получает ид инвойса, дату, имя продавца, сумму продаж, для продаж  с суммой > 2700
также выводится сумма собранных товаров по исходным заказам для выведененго инвойса,
результат сортирует по убыванию суммы инвойчас

TODO: напишите здесь свое решение*/

UPDATE STATISTICS Sales.Invoices WITH FULLSCAN;
UPDATE STATISTICS Sales.InvoiceLines WITH FULLSCAN;

USE WideWorldImporters

SET STATISTICS IO, TIME ON

IF OBJECT_ID('tempdb..#SalesTab') IS NOT NULL   DROP TABLE #SalesTab;
IF OBJECT_ID('tempdb..#TabOrderFromInvoice') IS NOT NULL     DROP TABLE #TabOrderFromInvoice;

go 
;with SalesTotalsCTE as (SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000)

Select InvoiceId, TotalSumm 
into #SalesTab
from SalesTotalsCTE

Select OrderID,
Sales.Invoices.InvoiceID
into #TabOrderFromInvoice
From Sales.Invoices
join #SalesTab on #SalesTab.InvoiceID = Sales.Invoices.OrderID

;with OrderPickinCompleteCTE as (
SELECT SUM(lines.PickedQuantity*lines.UnitPrice) as TotalSummForPickedItems,
Sales.Orders.OrderID
FROM Sales.Orders
join sales.OrderLines as lines on  Orders.OrderId = lines.OrderID
WHERE Orders.PickingCompletedWhen IS NOT NULL
group by Sales.Orders.OrderID) 

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	FullName,
	#SalesTab.TotalSumm as TotalSumm,
	OrderPickinCompleteCTE.TotalSummForPickedItems
FROM Sales.Invoices 
join #SalesTab on Invoices.InvoiceID = #SalesTab.InvoiceID
join Application.People on People.PersonID = Invoices.SalespersonPersonID
join OrderPickinCompleteCTE on OrderPickinCompleteCTE.OrderID =  Invoices.OrderID
Order by TotalSumm DESC
