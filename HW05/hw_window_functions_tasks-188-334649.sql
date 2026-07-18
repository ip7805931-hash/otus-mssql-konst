/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters



/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

 set statistics time, io on

USE WideWorldImporters;
GO


WITH SalesByMonthCTE AS
(
    SELECT 
        Inv.[CustomerID] as Customer,
        DATEFROMPARTS(YEAR(Inv.[InvoiceDate]), MONTH(Inv.[InvoiceDate]), 1) AS SaleMONTH,
        SUM(Lines.[ExtendedPrice]) AS TotalExtendedPrice     
    FROM [Sales].[Invoices] AS Inv
    LEFT JOIN Sales.InvoiceLines AS Lines ON Inv.InvoiceID = Lines.InvoiceID
    GROUP BY 
        Inv.[CustomerID],
        DATEFROMPARTS(YEAR(Inv.[InvoiceDate]), MONTH(Inv.[InvoiceDate]), 1)
)
,

TotalSumRuningTab AS
(
SELECT 
    t1.Customer, 
    t1.SaleMONTH,    
    SUM(t2.TotalExtendedPrice) AS RunningTotalSales 
FROM SalesByMonthCTE AS t1
LEFT JOIN SalesByMonthCTE AS t2 ON t1.Customer = t2.Customer 
    AND t2.SaleMONTH <= t1.SaleMONTH 
GROUP BY 
    t1.Customer, 
    t1.SaleMONTH
) 

SELECT 
    Inv.[InvoiceID],
    Inv.[CustomerID],
    Inv.[InvoiceDate],      
    SUM(Lines.[ExtendedPrice]) AS InvoiceSum, 
    Cust.[CustomerName],
    M_Sales.RunningTotalSales AS MonthlyClientSales 
FROM [Sales].[Invoices] AS Inv
LEFT JOIN Sales.InvoiceLines AS Lines ON Inv.InvoiceID = Lines.InvoiceID
LEFT JOIN Sales.Customers AS Cust ON Cust.CustomerID = Inv.CustomerID
LEFT JOIN TotalSumRuningTab AS M_Sales ON M_Sales.Customer = Inv.CustomerID 
    AND M_Sales.SaleMONTH = DATEFROMPARTS(YEAR(Inv.[InvoiceDate]), MONTH(Inv.[InvoiceDate]), 1)
where Inv.[InvoiceDate] > '2015-01-01'
GROUP BY 
    Inv.[InvoiceID],
    Inv.[CustomerID],
    Inv.[InvoiceDate],
    Cust.[CustomerName],
    M_Sales.RunningTotalSales
ORDER BY 
    Cust.[CustomerName], 
    Inv.[InvoiceDate]
;

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
 set statistics time, io on

SELECT 
    Inv.[InvoiceID],
    Inv.[CustomerID],
    Inv.[InvoiceDate],      
    
    SUM(Lines.[ExtendedPrice]) OVER ( PARTITION BY Inv.[CustomerID]
        ORDER BY DATEFROMPARTS(YEAR(Inv.[InvoiceDate]), MONTH(Inv.[InvoiceDate]), 1)
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS TotalSumRunning,
    Cust.[CustomerName]
FROM [Sales].[Invoices] AS Inv
LEFT JOIN Sales.InvoiceLines AS Lines ON Inv.InvoiceID = Lines.InvoiceID
LEFT JOIN Sales.Customers AS Cust ON Cust.CustomerID = Inv.CustomerID
where  Inv.[InvoiceDate] > '2015-01-01'

   ORDER by
Cust.[CustomerName], Inv.[InvoiceDate], Inv.[InvoiceID];




/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/


USE WideWorldImporters;
go
WITH SalesByMonthCTE_2 AS(
SELECT 
   DATEFROMPARTS(YEAR(Inv.[InvoiceDate]), MONTH(Inv.[InvoiceDate]), 1) as mounth,     
    [StockItemName],
 Sum( Quantity) AS Salesum,
 ROW_NUMBER () OVER ( PARTITION BY DATEFROMPARTS(YEAR(Inv.[InvoiceDate]), MONTH(Inv.[InvoiceDate]), 1)
        ORDER BY Sum( Quantity) Desc) as Num
FROM [Sales].[Invoices] AS Inv
LEFT JOIN Sales.InvoiceLines AS Lines ON Inv.InvoiceID = Lines.InvoiceID
LEFT JOIN [Warehouse].[StockItems] as Goods ON Lines.[StockItemID] = Goods.[StockItemID]
where  Inv.[InvoiceDate] between '2016-01-01' and '2016-12-31'
group by  DATEFROMPARTS(YEAR(Inv.[InvoiceDate]), MONTH(Inv.[InvoiceDate]), 1),  [StockItemName])


Select *
from SalesByMonthCTE_2
where Num < 3
  

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/
USE WideWorldImporters;
Select [StockItemID],[StockItemName],[Brand],[UnitPrice], LEFT(StockItemName, 1),
ROW_NUMBER() OVER (PARTITION BY LEFT(StockItemName, 1) ORDER BY [StockItemName]) as Num,
COUNT ([StockItemID]) OVER () as TotalKol ,
COUNT([StockItemID]) OVER (PARTITION BY LEFT(StockItemName, 1)) AS FirstLetter,
LEAD ([StockItemID]) OVER (ORDER BY [StockItemName]) As SledTovar,
LAG ([StockItemID]) OVER (ORDER BY [StockItemName]) As PredTovar,
LAG([StockItemName], 2, 'No items') OVER (ORDER BY [StockItemName]),
   NTILE(30) OVER (
        ORDER BY [TypicalWeightPerUnit] ASC
    ) AS Weight
from  
[Warehouse].[StockItems]
ORDER BY[StockItemName]   
/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/
USE WideWorldImporters;
GO

WITH OrderSumsCTE AS (
  
    SELECT 
        Inv.SalespersonPersonID AS ManagerID,
        Inv.CustomerID,
        Inv.InvoiceDate,
        Inv.InvoiceID,
        SUM(Lines.ExtendedPrice) AS Ammount
    FROM Sales.Invoices AS Inv
    INNER JOIN Sales.InvoiceLines AS Lines ON Inv.InvoiceID = Lines.InvoiceID
    GROUP BY 
        Inv.SalespersonPersonID,
        Inv.CustomerID,
        Inv.InvoiceDate,
        Inv.InvoiceID
),
RankedSalesCTE AS (

    SELECT 
        ManagerID,
        CustomerID,
        InvoiceDate,
        Ammount,
        ROW_NUMBER() OVER (
            PARTITION BY ManagerID 
            ORDER BY InvoiceDate DESC, InvoiceID DESC
        ) AS Num
    FROM OrderSumsCTE
)
SELECT 
    Sales.ManagerID AS [Salesperson ID],
    People.FullName AS [Salesperson Name],
    Sales.CustomerID AS [Customer ID],
    Customers.CustomerName AS [Customer Name],
    Sales.InvoiceDate AS [Last Sale Date],
    Sales.Ammount AS [Transaction Ammount]
FROM RankedSalesCTE AS Sales
INNER JOIN Sales.Customers AS Customers ON Customers.CustomerID = Sales.CustomerID
INNER JOIN Application.People AS People ON People.PersonID = Sales.ManagerID
WHERE Sales.Num = 1
ORDER BY People.FullName;


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/


SELECT 
    TopSale.CustomerID,
    TopSale.CustomerName,
    TopSale.StockItemID,
    TopSale.Price,
    TopSale.InvoiceDate
FROM (
    SELECT
        Inv.CustomerID,
        Cust.CustomerName,      
        Lines.StockItemID,
        Lines.UnitPrice AS Price,
        Inv.InvoiceDate,
        ROW_NUMBER() OVER (
            PARTITION BY Inv.CustomerID 
            ORDER BY Lines.UnitPrice DESC
        ) AS Num
    FROM [Sales].[InvoiceLines] AS Lines
    INNER JOIN [Sales].[Invoices] AS Inv 
        ON Inv.InvoiceID = Lines.InvoiceID
    INNER JOIN [Warehouse].[StockItems] AS Goods 
        ON Goods.StockItemID = Lines.StockItemID
    INNER JOIN [Sales].[Customers] AS Cust 
        ON Cust.CustomerID = Inv.CustomerID 
) AS TopSale
WHERE TopSale.Num <= 2
ORDER BY TopSale.CustomerID, TopSale.Num;

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 