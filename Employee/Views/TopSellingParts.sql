-- Представление по продажам запчастей
DROP VIEW IF EXISTS VW_TopSellingParts;
GO
CREATE VIEW VW_TopSellingParts AS
SELECT 
    p.PartId,
    p.Name AS [Название запчасти],
    c.Name AS [Категория],
    (SELECT Name FROM Categories WHERE CategoryId = cat.ParentCategoryId) AS [Родительская категория],
    s.Name AS [Поставщик],
    SUM(oi.Quantity) AS [Продано шт],
    SUM(oi.TotalPrice) AS [Общая выручка],
    AVG(oi.UnitPrice) AS [Средняя цена],
    COUNT(DISTINCT o.ClientId) AS [Уникальных покупателей],
    AVG(oi.Quantity) AS [Среднее количество в заказе]
FROM Orders AS o
JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
JOIN Parts AS p ON oi.PartId = p.PartId
JOIN Categories AS c ON p.CategoryId = c.CategoryId
JOIN Categories AS cat ON p.CategoryId = cat.CategoryId
JOIN Suppliers AS s ON p.SupplierId = s.SupplierId
WHERE o.Status = 'completed'
  AND oi.ItemType = 'part'
GROUP BY 
    p.PartId,
    p.Name, 
    c.Name,
    cat.ParentCategoryId,
    s.Name;
GO