-- Представление всех клиентов
DROP VIEW IF EXISTS VW_ClientsStatus;
GO
CREATE VIEW VW_ClientsStatus AS
SELECT 
    c.FullName AS ClientName,
    c.Email AS ClientEmail,
	dbo.FN_GetClientStatus(COUNT(o.OrderId)) AS Status
FROM Orders AS o
RIGHT JOIN Clients AS c ON o.ClientId = c.ClientId
WHERE c.IsArchived = 0
GROUP BY c.ClientId, c.FullName, c.Email
GO
SELECT * FROM VW_ClientsStatus
-- Представление всех заказов
DROP VIEW IF EXISTS VW_AllOrders;
GO
CREATE VIEW VW_AllOrders AS
SELECT 
    o.OrderId,
    o.OrderDate,
    dbo.FN_GetOrderStatusText(o.Status) AS Status,
    c.FullName AS ClientName,
    c.Email AS ClientEmail,
    e.FullName AS ManagerName,
    COUNT(oi.OrderItemId) AS ItemsCount,
    SUM(oi.TotalPrice) AS TotalAmount,
    i.InvoiceId,
    i.IssueDate AS InvoiceDate
FROM Orders AS o
JOIN Clients AS c ON o.ClientId = c.ClientId
LEFT JOIN Employees AS e ON o.EmployeeId = e.EmployeeId
LEFT JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
LEFT JOIN Invoices AS i ON o.OrderId = i.OrderId
GROUP BY o.OrderId, o.OrderDate, o.Status, c.FullName, c.Email, 
         e.FullName, i.InvoiceId, i.IssueDate;
GO