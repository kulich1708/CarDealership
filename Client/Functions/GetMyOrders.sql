-- Все заказы конкретного клиента
DROP FUNCTION IF EXISTS FN_GetMyOrders;
GO
CREATE FUNCTION FN_GetMyOrders (@ClientId INT)
RETURNS TABLE AS
RETURN (
	SELECT 
		o.OrderId,
		o.OrderDate,
		o.Status,
		COUNT(oi.OrderItemId) AS ItemsCount,
		SUM(oi.TotalPrice) AS TotalAmount,
		i.InvoiceId,
		i.DueDate
	FROM Orders o
	LEFT JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
	LEFT JOIN Invoices AS i ON o.OrderId = i.OrderId
	WHERE o.ClientId = @ClientId
	GROUP BY o.OrderId, o.OrderDate, o.Status, i.InvoiceId, i.DueDate);
GO

SELECT * FROM FN_GetMyOrders(4);
GO
