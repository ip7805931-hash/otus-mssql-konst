/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

USE WideWorldImporters;
GO

;WITH SourceData AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(Inv.InvoiceDate),
            MONTH(Inv.InvoiceDate),
            1
        ) AS InvoiceMonth,
        SUBSTRING(
            Cust.CustomerName,
            CHARINDEX('(', Cust.CustomerName) + 1,
            CHARINDEX(')', Cust.CustomerName)
                - CHARINDEX('(', Cust.CustomerName) - 1
        ) AS CustomerLocation,
        Inv.InvoiceID
    FROM Sales.Invoices AS Inv
    INNER JOIN Sales.Customers AS Cust
        ON Cust.CustomerID = Inv.CustomerID
    WHERE Cust.CustomerID BETWEEN 2 AND 6
)
SELECT
    CONVERT(char(10), P.InvoiceMonth, 104) AS InvoiceMonth,
    P.[Peeples Valley, AZ],
    P.[Medicine Lodge, KS],
    P.[Gasport, NY],
    P.[Sylvanite, MT],
    P.[Jessie, ND]
FROM SourceData
PIVOT
(
    COUNT(InvoiceID)
    FOR CustomerLocation IN
    (
        [Peeples Valley, AZ],
        [Medicine Lodge, KS],
        [Gasport, NY],
        [Sylvanite, MT],
        [Jessie, ND]
    )
) AS P
ORDER BY P.InvoiceMonth;

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

;WITH CustomerAddresses AS
(
    SELECT
        CustomerID,
        CustomerName,
        DeliveryAddressLine1,
        DeliveryAddressLine2,
        PostalAddressLine1,
        PostalAddressLine2
    FROM Sales.Customers
    WHERE CustomerName LIKE N'%Tailspin Toys%'
)
SELECT
    Addr.CustomerName,
    Addr.AddressLine
FROM CustomerAddresses
UNPIVOT
(
    AddressLine FOR AddressField IN
    (
        DeliveryAddressLine1,
        DeliveryAddressLine2,
        PostalAddressLine1,
        PostalAddressLine2
    )
) AS Addr
WHERE NULLIF(LTRIM(RTRIM(Addr.AddressLine)), N'') IS NOT NULL
ORDER BY
    Addr.CustomerID,
    CASE Addr.AddressField
        WHEN 'DeliveryAddressLine1' THEN 1
        WHEN 'DeliveryAddressLine2' THEN 2
        WHEN 'PostalAddressLine1'   THEN 3
        WHEN 'PostalAddressLine2'   THEN 4
    END;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT
    Countries.CountryID,
    Countries.CountryName,
    Codes.Code
FROM Application.Countries AS Countries
CROSS APPLY
(
    VALUES
        (1, CAST(Countries.IsoAlpha3Code AS nvarchar(10))),
        (2, CAST(Countries.IsoNumericCode AS nvarchar(10)))
) AS Codes(SortOrder, Code)
WHERE Codes.Code IS NOT NULL
ORDER BY
    Countries.CountryID,
    Codes.SortOrder;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT
    Cust.CustomerID,
    Cust.CustomerName,
    Products.StockItemID,
    Products.Price,
    PurchaseDate.InvoiceDate
FROM Sales.Customers AS Cust
CROSS APPLY
(
    SELECT TOP (2)
        Lines.StockItemID,
        MAX(Lines.UnitPrice) AS Price
    FROM Sales.Invoices AS Inv
    INNER JOIN Sales.InvoiceLines AS Lines
        ON Lines.InvoiceID = Inv.InvoiceID
    WHERE Inv.CustomerID = Cust.CustomerID
    GROUP BY Lines.StockItemID
    ORDER BY
        MAX(Lines.UnitPrice) DESC,
        Lines.StockItemID
) AS Products
CROSS APPLY
(
    SELECT
        MAX(Inv.InvoiceDate) AS InvoiceDate
    FROM Sales.Invoices AS Inv
    INNER JOIN Sales.InvoiceLines AS Lines
        ON Lines.InvoiceID = Inv.InvoiceID
    WHERE Inv.CustomerID = Cust.CustomerID
      AND Lines.StockItemID = Products.StockItemID
      AND Lines.UnitPrice = Products.Price
) AS PurchaseDate
ORDER BY
    Cust.CustomerID,
    Products.Price DESC,
    Products.StockItemID;
