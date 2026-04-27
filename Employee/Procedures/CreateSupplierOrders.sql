DROP PROCEDURE IF EXISTS usp_CreateSupplierOrders;
GO
CREATE PROCEDURE usp_CreateSupplierOrders(@PartsToOrder PartsToOrderType READONLY) AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS (SELECT 1 FROM @PartsToOrder)
		THROW 50001, N'Нет данных для создания заказа поставщику', 1;

	-- Таблица, В которую запишутся соответствия id поставщика и id заказа
    DECLARE @NewOrders TABLE (
        SupplierOrderId INT,
        SupplierId INT,
		EmployeeId INT
    );

	-- Создаём по 1 заказу, на каждого нужного поставщика и записываем эти данные в NewOrders
    INSERT INTO SupplierOrders (SupplierId, EmployeeId)
    OUTPUT inserted.SupplierOrderId, inserted.SupplierId , inserted.EmployeeId
    INTO @NewOrders
    SELECT DISTINCT p.SupplierId, pto.EmployeeId
    FROM @PartsToOrder AS pto
	JOIN Parts AS p ON pto.PartId = p.PartId;
	
	-- Создаём все необходимые позиции для заказов
    INSERT INTO SupplierOrderItems (SupplierOrderId, PartId, Quantity, UnitCost)
    SELECT
        no.SupplierOrderId,
        pto.PartId,
        pto.Quantity, 
        pto.UnitPrice
    FROM @PartsToOrder AS pto
	JOIN Parts AS p ON p.PartId = pto.PartId
    JOIN @NewOrders AS no ON no.SupplierId = p.SupplierId AND no.EmployeeId = pto.EmployeeId OR no.EmployeeId IS NULL;
END
GO