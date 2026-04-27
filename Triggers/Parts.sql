DROP TRIGGER IF EXISTS TR_Parts_Delete
GO
CREATE TRIGGER TR_Parts_Delete
ON Parts INSTEAD OF DELETE AS 
BEGIN 
	SET NOCOUNT ON;
	
    BEGIN TRY
		BEGIN TRANSACTION;
		DELETE FROM InventoryMovements
		WHERE PartId IN (SELECT PartId FROM deleted);

		DELETE FROM OrderItems
		WHERE PartId IN (SELECT PartId FROM deleted);
		
		DELETE FROM SupplierOrderItems
		WHERE PartId IN (SELECT PartId FROM deleted);

		DELETE FROM Parts
		WHERE PartId IN (SELECT PartId FROM deleted);
	
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

DROP TRIGGER IF EXISTS TR_Parts_CheckQuantity;
GO
CREATE TRIGGER TR_Parts_CheckQuantity
ON Parts
FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON

	IF UPDATE(CategoryId) OR UPDATE(Quantity)
	BEGIN
        DECLARE @PartsToOrder PartsToOrderType;
		INSERT INTO @PartsToOrder (PartId, Quantity, UnitPrice)
		SELECT PartId, c.MinStockThreshold, Price * 0.8
        FROM inserted AS i
        JOIN Categories AS c ON i.CategoryId = c.CategoryId
        WHERE i.Quantity <= c.MinStockThreshold 
			AND i.IsReordered = 0 AND i.SupplierId IS NOT NULL;

		IF EXISTS (SELECT 1 FROM @PartsToOrder)
			EXEC usp_CreateSupplierOrders @PartsToOrder = @PartsToOrder;
	END
END
GO
