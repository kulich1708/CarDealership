DROP TRIGGER IF EXISTS TR_SupplierOrders_Delete;
GO
CREATE TRIGGER TR_SupplierOrders_Delete
ON SupplierOrders INSTEAD OF DELETE
AS 
BEGIN 
	SET NOCOUNT ON;
	
    BEGIN TRY
		BEGIN TRANSACTION;
		DELETE FROM SupplierOrderItems
		WHERE SupplierOrderId IN (SELECT SupplierOrderId FROM deleted);

		DELETE FROM SupplierOrders
		WHERE SupplierOrderId IN (SELECT SupplierOrderId FROM deleted);
	
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


DROP TRIGGER IF EXISTS TR_SupplierOrders_Insert;
GO
CREATE TRIGGER TR_SupplierOrders_Insert
ON SupplierOrders
FOR INSERT
AS
BEGIN
	IF EXISTS (SELECT 1
	FROM inserted
	WHERE Status != 'pending')
	BEGIN
		ROLLBACK;
		THROW 50006, N'Запрещено добавление заказов поставщикам со статусом не "pending". ВНИМАНИЕ: Из-за ошибки не добавилась ни одна запись', 1;
	END
END
GO

DROP TRIGGER IF EXISTS TR_SupplierOrders_UpdateStatus;
GO
CREATE TRIGGER TR_SupplierOrders_UpdateStatus
ON SupplierOrders
FOR UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF UPDATE(Status)
	BEGIN
		IF EXISTS (SELECT 1
		FROM deleted
		JOIN inserted ON deleted.SupplierOrderId = inserted.SupplierOrderId
		WHERE 
		deleted.Status IN ('completed', 'cancelled'))
		BEGIN
			ROLLBACK;
			THROW 50007, N'Запрещено менять статус заказа с "completed" или с "cancelled". ВНИМАНИЕ: Из-за ошибки не обновилась ни одна запись', 1;
		END

		SELECT
		PartId, Quantity, 
		SupplierOrderItemId, Status
		INTO #SupplierOrderItems
		FROM inserted
		JOIN SupplierOrderItems ON inserted.SupplierOrderId = SupplierOrderItems.SupplierOrderId
		WHERE inserted.Status IN ('completed', 'cancelled');

		-- Получаем, если статус заказа выполнен
		INSERT INTO InventoryMovements(
		ItemType, PartId, Quantity, 
		SupplierOrderItemId, MovementType)
		SELECT
		'part', PartId, Quantity, 
		SupplierOrderItemId, 'incoming'
		FROM #SupplierOrderItems
		WHERE Status = 'completed';

		-- Запускаем процедуру для правильной расстановки статусов перезаказа
		DECLARE @PartsIdTable PartsIdType;
		INSERT INTO @PartsIdTable (PartId)
		SELECT PartId FROM #SupplierOrderItems;
		EXEC usp_ResetReorderStatus @PartsId = @PartsIdTable

		-- Вызываем процедуру для создания счёт-фактур для всех завершённых заказов
		DECLARE @InvoiceData InvoiceDataCommonType;
		INSERT INTO @InvoiceData
		SELECT SupplierOrderId, NULL, NULL
		FROM inserted
		WHERE inserted.Status = ('completed');
		EXEC usp_CreateSupplierInvoices @InvoiceData;
	END
END
GO
