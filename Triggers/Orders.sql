DROP TRIGGER IF EXISTS TR_Orders_Delete;
GO
CREATE TRIGGER TR_Orders_Delete
ON Orders INSTEAD OF DELETE AS
BEGIN
	SET NOCOUNT ON;
	
    BEGIN TRY
		BEGIN TRANSACTION;
		DELETE FROM OrderItems
		WHERE OrderId IN (SELECT OrderId FROM deleted);

		DELETE FROM Orders
		WHERE OrderId IN (SELECT OrderId FROM deleted);
	
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

DROP TRIGGER IF EXISTS TR_Orders_Insert;
GO
CREATE TRIGGER TR_Orders_Insert
ON Orders
FOR INSERT
AS
BEGIN
	IF EXISTS (SELECT 1
	FROM inserted
	WHERE Status != 'pending')
	BEGIN
		ROLLBACK;
		THROW 50001, N'Запрещено добавление заказов со статусом не "pending". ВНИМАНИЕ: Из-за ошибки не добавилась ни одна запись', 1;
	END
END
GO

DROP TRIGGER IF EXISTS TR_Orders_UpdateStatus;
GO
CREATE TRIGGER TR_Orders_UpdateStatus
ON Orders
FOR UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF UPDATE(Status)
	BEGIN
		IF EXISTS (SELECT 1
		FROM deleted
		JOIN inserted ON deleted.OrderId = inserted.OrderId
		WHERE 
		deleted.Status IN ('completed', 'cancelled')
			AND deleted.Status != inserted.Status)
		BEGIN
			ROLLBACK;
			THROW 50002, N'Запрещено менять статус заказа с "completed" или с "cancelled". ВНИМАНИЕ: Из-за ошибки не обновилась ни одна запись', 1;
		END

		-- Отменяем резервирование, если статус заказа закрыт
		INSERT INTO InventoryMovements(
		ItemType, PartId, CarId, Quantity, 
		OrderItemId, MovementType)
		SELECT
		ItemType, PartId, CarId, Quantity, 
		OrderItemId, 'unreserve'
		FROM inserted
		JOIN deleted ON inserted.OrderId = deleted.OrderId
		JOIN OrderItems ON inserted.OrderId = OrderItems.OrderId
		WHERE inserted.Status = 'cancelled'
			AND deleted.Status != inserted.Status;

		-- Выдаём, если статус заказа выполнен
		INSERT INTO InventoryMovements(
		ItemType, PartId, CarId, Quantity, 
		OrderItemId, MovementType)
		SELECT
		ItemType, PartId, CarId, Quantity, 
		OrderItemId, 'outgoing'
		FROM inserted
		JOIN deleted ON inserted.OrderId = deleted.OrderId
		JOIN OrderItems ON inserted.OrderId = OrderItems.OrderId
		WHERE inserted.Status IN ('completed')
			AND deleted.Status != inserted.Status;

		-- Вызываем процедуру для создания счёт-фактур для всех завершённых заказов
		DECLARE @InvoiceData InvoiceDataCommonType;
		INSERT INTO @InvoiceData
		SELECT inserted.OrderId, NULL, NULL
		FROM inserted
		JOIN deleted ON inserted.OrderId = deleted.OrderId
		WHERE inserted.Status = ('completed')
			AND deleted.Status != inserted.Status;
		EXEC usp_CreateInvoices @InvoiceData;
	END
END
GO