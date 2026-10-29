/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/


USE WideWorldImporters;
GO

DECLARE @Columns nvarchar(max);
DECLARE @SQL nvarchar(max);


SELECT @Columns = STUFF(
    (
        SELECT N',' + QUOTENAME(Cust.CustomerName)
        FROM Sales.Customers AS Cust
        ORDER BY Cust.CustomerName
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'),
    1,
    1,
    N''
);

SET @SQL = N'
;WITH SourceData AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(Inv.InvoiceDate),
            MONTH(Inv.InvoiceDate),
            1
        ) AS InvoiceMonth,
        Cust.CustomerName,
        Inv.InvoiceID
    FROM Sales.Invoices AS Inv
    INNER JOIN Sales.Customers AS Cust
        ON Cust.CustomerID = Inv.CustomerID
)
SELECT
    CONVERT(char(10), P.InvoiceMonth, 104) AS InvoiceMonth,
    ' + @Columns + N'
FROM SourceData
PIVOT
(
    COUNT(InvoiceID)
    FOR CustomerName IN (' + @Columns + N')
) AS P
ORDER BY P.InvoiceMonth;
';

EXEC sys.sp_executesql @SQL;
