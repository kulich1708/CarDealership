-- Триггеры на добавление машин
DROP TRIGGER IF EXISTS TR_CarInventory_Movements;
GO
CREATE TRIGGER TR_CarInventory_Movements
ON CarInventory FOR INSERT AS
BEGIN
	INSERT INTO InventoryMovements (ItemType, CarId, Quantity, MovementType)
	SELECT 'car', CarId, 1, 'incoming'
	FROM inserted
END