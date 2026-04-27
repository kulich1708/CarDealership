-- Создание заказа поставщику
DROP PROCEDURE IF EXISTS usp_CreateSupplierOrder;
GO
CREATE PROCEDURE usp_CreateSupplierOrder (@PartId INT, @EmployeeId INT = NULL, @Quantity INT, @UnitPrice INT) AS 
BEGIN
	SET NOCOUNT ON;
	IF (SELECT SupplierId FROM Parts WHERE PartId = @PartId) IS NULL
	BEGIN
		PRINT N'У товара ' + CAST(@PartId AS NVARCHAR(10)) + N' не указан поставщик, поэтому заказать его не получится.';
		RETURN;
	END
	DECLARE @PartsToOrder PartsToOrderType;
	INSERT INTO @PartsToOrder (PartId, EmployeeId, Quantity, UnitPrice)
	VALUES(@PartId, @EmployeeId, @Quantity, @UnitPrice);

	EXEC usp_CreateSupplierOrders @PartsToOrder = @PartsToOrder;
END
GO
