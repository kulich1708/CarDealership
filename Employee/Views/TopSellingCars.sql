-- Представление по продажам авто
DROP VIEW IF EXISTS VW_TopSellingCars;
GO
CREATE VIEW VW_TopSellingCars AS
SELECT 
    b.BrandName AS [Марка],
    m.ModelName AS [Модель],
    g.GenerationName AS [Поколение],
    ct.TrimName AS [Комплектация],
	CASE 
		WHEN ci.Mileage > 0 THEN 'БУ'
		WHEN ci.Mileage = 0 THEN 'Новый'
	END AS [Состояние],
    COUNT(*) AS [Продано шт],
    SUM(oi.TotalPrice) AS [Общая выручка],
    AVG(oi.UnitPrice) AS [Средняя цена],
    COUNT(DISTINCT o.ClientId) AS [Уникальных покупателей],
    AVG(oi.Quantity) AS [Среднее количество в заказе]
FROM Orders AS o
JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
JOIN CarInventory AS ci ON oi.CarId = ci.CarId
JOIN CarTrims AS ct ON ci.TrimId = ct.TrimId
JOIN ModelGenerations AS g ON ct.GenerationId = g.GenerationId
JOIN CarModels AS m ON g.ModelId = m.ModelId
JOIN Brands AS b ON m.BrandId = b.BrandId
WHERE o.Status = 'completed'
	AND oi.ItemType = 'car'
GROUP BY 
    b.BrandName, 
    m.ModelName, 
    g.GenerationName, 
    ct.TrimName,
    CASE 
        WHEN ci.Mileage > 0 THEN 'БУ'
        WHEN ci.Mileage = 0 THEN 'Новый'
    END;;
GO
