/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
SELECT 
Year(InvoiceDate) as year,
Month(InvoiceDate) as mounth,
avg(UnitPrice) as price,
sum(ExtendedPrice) as sale_sum
FROM Sales.Invoices as Invoice
LEFT JOIN Sales.InvoiceLines as lines on Invoice.InvoiceID = lines.InvoiceID
GROUP BY Year(InvoiceDate), Month(InvoiceDate)
order by year desc, mounth desc


/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
Year(InvoiceDate) as year,
Month(InvoiceDate) as mounth,
sum(ExtendedPrice) as sale_sum
FROM Sales.Invoices as Invoice
LEFT JOIN Sales.InvoiceLines as lines on Invoice.InvoiceID = lines.InvoiceID
GROUP BY Year(InvoiceDate), Month(InvoiceDate)
having sum(ExtendedPrice) > 4600000 
order by year desc, mounth desc


/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
Year(InvoiceDate) as year,
Month(InvoiceDate) as mounth,
sum(ExtendedPrice) as sale_sum,
min(t_first_sale.first_sale) as first_sale,
max(StockItemName) as name_good,
sum([Quantity]) as kol 
FROM Sales.Invoices as Invoice
LEFT JOIN Sales.InvoiceLines as lines on Invoice.InvoiceID = lines.InvoiceID
LEFT JOIN  [Warehouse].[StockItems] as goods on lines.StockItemID = goods.StockItemID
LEFT JOIN (SELECT 
min(InvoiceDate) as first_sale,
lines.StockItemID 
FROM Sales.Invoices as Invoice
LEFT JOIN Sales.InvoiceLines as lines on Invoice.InvoiceID = lines.InvoiceID
LEFT JOIN  [Warehouse].[StockItems] as goods on lines.StockItemID = goods.StockItemID
group by lines.StockItemID) as t_first_sale on t_first_sale.StockItemID =  lines.StockItemID
GROUP BY Year(InvoiceDate), Month(InvoiceDate),lines.StockItemID 
 having sum([Quantity]) < 50 
order by  sum([Quantity]) desc, year desc, mounth desc



-- ---------------------------------------------------------------------------
-- Опционально 
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
