-- Отчет по продажам 
GO
DROP PROCEDURE IF EXISTS usp_GetSalesReport;
GO
CREATE PROCEDURE usp_GetSalesReport
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;
    IF @StartDate IS NULL SET @StartDate = DATEADD(MONTH, -1, GETDATE());
    IF @EndDate IS NULL SET @EndDate = GETDATE();
    
    -- Общая статистика
    SELECT 
        'Общая статистика' AS ReportType,
        COUNT(DISTINCT o.OrderId) AS OrdersCount,
        COUNT(DISTINCT o.ClientId) AS UniqueClients,
        SUM(oi.TotalPrice) AS TotalRevenue,
        AVG(oi.TotalPrice) AS AverageOrder
    FROM Orders AS o
    JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
    WHERE CAST(o.OrderDate AS DATE) BETWEEN @StartDate AND @EndDate AND
		o.Status = 'completed';
	PRINT @StartDate
	PRINT @EndDate
    
    -- Продажи по типам товаров
    SELECT 
        'По типам товаров' AS ReportType,
        oi.ItemType,
        COUNT(*) AS ItemsSold,
        SUM(oi.Quantity) AS TotalQuantity,
        SUM(oi.TotalPrice) AS Revenue
    FROM Orders AS o
    JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
    WHERE CAST(o.OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
      AND o.Status = 'completed'
    GROUP BY oi.ItemType;
    
    -- Топ товаров
    SELECT * FROM VW_TopSellingCars;
    SELECT * FROM VW_TopSellingParts;
	SELECT 
	CONCAT(Марка, Модель, Поколение, Комплектация) AS [Название],
	Состояние AS Категория,
	'Авто' AS [Родительская категория],
	[Продано шт],
	[Общая выручка],
	[Средняя цена],
	[Уникальных покупателей],
	[Среднее количество в заказе]
	FROM VW_TopSellingCars AS tsc
	UNION
	SELECT 
	[Название запчасти] AS [Название],
	Категория,
	[Родительская категория],
	[Продано шт],
	[Общая выручка],
	[Средняя цена],
	[Уникальных покупателей],
	[Среднее количество в заказе]
	FROM VW_TopSellingParts AS tsp
	ORDER BY [Общая выручка];
END
GO