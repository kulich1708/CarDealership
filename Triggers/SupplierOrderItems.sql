DROP TRIGGER IF EXISTS TR_SupplierOrderItems_Delete;
GO
CREATE TRIGGER TR_SupplierOrderItems_Delete
ON SupplierOrderItems FOR DELETE
AS 
BEGIN 
	SET NOCOUNT ON;
	-- Запускаем процедуру для правильной расстановки статусов перезаказа
	DECLARE @PartsIdTable PartsIdType;
	INSERT INTO @PartsIdTable (PartId)
	SELECT DISTINCT PartId FROM deleted;
	EXEC usp_ResetReorderStatus @PartsId = @PartsIdTable
END
GO

DROP TRIGGER IF EXISTS TR_SupplierOrderItems_Insert;
GO
CREATE TRIGGER TR_SupplierOrderItems_Insert
ON SupplierOrderItems
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1
	FROM inserted
	JOIN SupplierOrders ON inserted.SupplierOrderId = SupplierOrders.SupplierOrderId
	WHERE Status != 'pending')
	BEGIN
		ROLLBACK;
		THROW 50008, N'Запрещено добавление товаров в заказ поставщику со статусом не "pending". ВНИМАНИЕ: Из-за ошибки не добавилась ни одна запись', 1;
	END
	

	UPDATE Parts
	SET IsReordered = 1
	FROM Parts
	JOIN inserted ON Parts.PartId = inserted.PartId
	WHERE Parts.IsReordered = 0;
END
GO

-- Протестирован
DROP TRIGGER IF EXISTS TR_SupplierOrderItems_Update;
GO
CREATE TRIGGER TR_SupplierOrderItems_Update
ON SupplierOrderItems INSTEAD OF UPDATE
AS 
BEGIN 
	SET NOCOUNT ON;
	THROW 50009, 'Запрещено изменение товаров входящих в заказ поставщику. Для изменения удалите и создайте новый OrderItem', 1;
END
GO