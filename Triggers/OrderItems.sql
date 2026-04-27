DROP TRIGGER IF EXISTS TR_OrderItems_Delete;
GO
CREATE TRIGGER TR_OrderItems_Delete
ON OrderItems INSTEAD OF DELETE
AS 
BEGIN 
	SET NOCOUNT ON;
	
	DECLARE @OriginalContext VARBINARY(128) = CONTEXT_INFO();
	DECLARE @AllowDelete VARBINARY(128) = 0x44454C455445;
    SET CONTEXT_INFO @AllowDelete;

	BEGIN TRY
		DELETE FROM InventoryMovements
		WHERE OrderItemId IN (SELECT OrderItemId FROM deleted);

        SET CONTEXT_INFO @OriginalContext;
	END TRY
	BEGIN CATCH
		SET CONTEXT_INFO @OriginalContext;
		THROW;
	END CATCH

	DELETE FROM OrderItems
	WHERE OrderItemId IN (SElECT OrderItemId FROM deleted);
END
GO

DROP TRIGGER IF EXISTS TR_OrderItems_Insert;
GO
CREATE TRIGGER TR_OrderItems_Insert
ON OrderItems
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1
	FROM inserted
	JOIN Orders ON inserted.OrderId = Orders.OrderId
	WHERE Status != 'pending')
	BEGIN
		ROLLBACK;
		THROW 50003, N'Запрещено добавление товаров в заказ со статусом не "pending". ВНИМАНИЕ: Из-за ошибки не добавилась ни одна запись', 1;
	END

	
	-- Проверка на доступность такого количества товара
	IF EXISTS(
	SELECT 1
	FROM (SELECT PartId, SUM(Quantity) AS Quantity
	FROM inserted
	GROUP BY PartId) AS i
	JOIN Parts ON Parts.PartId = i.PartId
	WHERE Parts.Quantity < i.Quantity)
	BEGIN
		ROLLBACK;
		THROW 50004, N'Недостаточно деталей на складе.', 1;
	END
	
	-- Пересчитываем количество машин
	IF (SELECT MAX(Quantity)
	FROM (
		SELECT 
			SUM(Quantity) as Quantity
		FROM inserted
		WHERE ItemType = 'car'
		GROUP BY carId
	) AS d) > 1
	BEGIN
		ROLLBACK;
		THROW 50005, N'Нельзя добавить более одной одинаковой машины в один заказ.', 1;
	END

	-- Проверка на доступность машины
	IF EXISTS(SELECT 1
	FROM inserted
	JOIN CarInventory AS Cars ON Cars.CarId = inserted.CarId
	WHERE IsAvailable = 0)
	BEGIN
		ROLLBACK;
		THROW 50006, N'Нельзя добавить машину, которой нет в наличии.', 1;
	END
	
	
	-- Резервируем, если статус заказа в работе
	INSERT INTO InventoryMovements(
	ItemType, PartId, CarId, Quantity, 
	OrderItemId, MovementType)
	SELECT
	ItemType, PartId, CarId, Quantity, 
	inserted.OrderItemId, 'reserve'
	FROM inserted
	JOIN Orders ON inserted.OrderId = Orders.OrderId
	WHERE Orders.Status IN ('pending');
	
END

GO

DROP TRIGGER IF EXISTS TR_OrderItems_Update;
GO
CREATE TRIGGER TR_OrderItems_Update
ON OrderItems INSTEAD OF UPDATE
AS 
BEGIN 
	SET NOCOUNT ON;
	THROW 50005, 'Запрещено изменение товаров входящих в заказ. Для изменения удалите и создайте новый OrderItem', 1;
END
GO