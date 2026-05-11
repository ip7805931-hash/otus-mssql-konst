-- Все товары, в названии которых есть "urgent" или название начинается с "Animal".
use	WideWorldImporters;

select *
from Warehouse.StockItems as goods
where 
goods.StockItemName LIKE '%urgent%'
OR
goods.StockItemName LIKE 'Animal%'
