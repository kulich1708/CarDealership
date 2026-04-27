DROP TRIGGER IF EXISTS TR_InventoryMovements_Insert
GO
CREATE TRIGGER TR_InventoryMovements_Insert
ON InventoryMovements
FOR INSERT
AS
BEGIN
	-- Пересматриваем статус машины
	UPDATE ci
	SET IsAvailable = CASE 
		WHEN 
			inserted.MovementType IN ('incoming', 'unreserve') OR 
			inserted.MovementType = 'adjustment' AND inserted.Quantity = 1
		THEN 1
		ELSE 0
	END
	FROM CarInventory AS ci
	JOIN inserted ON ci.CarId = inserted.CarId
	WHERE inserted.ItemType = 'car';


	-- Пересчитываем количество товара
	WITH MovementSums AS (
		SELECT 
			PartId,
			SUM(CASE
				WHEN MovementType IN ('incoming', 'unreserve', 'adjustment')
					THEN Quantity
				WHEN MovementType IN ('reserve')
					THEN -Quantity
				ELSE 0
			END) as QuantityChange
		FROM inserted
		WHERE ItemType = 'part'
		GROUP BY PartId
	)
	UPDATE Parts
	SET Parts.Quantity += ms.QuantityChange
	FROM Parts
	JOIN MovementSums ms ON Parts.PartId = ms.PartId;
END
GO

-- Протестирован
DROP TRIGGER IF EXISTS TR_InventoryMovements_Update
GO
CREATE TRIGGER TR_InventoryMovements_Update
ON InventoryMovements
FOR UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(ItemType) 
        OR UPDATE(PartId) 
        OR UPDATE(CarId) 
        OR UPDATE(MovementType) 
        OR UPDATE(Quantity)
        OR UPDATE(OrderItemId) 
        OR UPDATE(SupplierOrderItemId) AND (SELECT SupplierOrderItemId FROM inserted) IS NOT NULL
        OR UPDATE(MovementDate)
    BEGIN
        ;THROW 50000, N'Изменять можно олько EmployeeId и Notes. Другие поля неизменяемы.', 1;
    END
END
GO