DROP TRIGGER IF EXISTS TR_InventoryMovements_Delete
GO
CREATE TRIGGER TR_InventoryMovements_Delete
ON InventoryMovements
FOR DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Проверяем, установлен ли специальный флаг разрешения 0x44454C455445
        IF CONTEXT_INFO() = 0x44454C455445 OR
			NOT EXISTS (SELECT 1 FROM deleted WHERE MovementType != 'adjustment' OR MovementType = 'adjustment' AND Quantity > 0)
		BEGIN
			DECLARE @AffectedParts TABLE (PartId INT);
			DECLARE @AffectedCars TABLE (CarId INT);
    
			INSERT INTO @AffectedParts (PartId)
			SELECT DISTINCT PartId FROM deleted WHERE PartId IS NOT NULL;
    
			INSERT INTO @AffectedCars (CarId)
			SELECT DISTINCT CarId FROM deleted WHERE CarId IS NOT NULL;
			
			WITH LastCarMovement AS (
				SELECT 
				im.CarId,
				im.MovementId,
				im.MovementType,
				im.Quantity,
				ROW_NUMBER() OVER (
					PARTITION BY im.CarId 
					ORDER BY im.MovementDate DESC, im.MovementId DESC
				) as rn
				FROM InventoryMovements AS im
				WHERE im.CarId IN (SELECT CarId FROM @AffectedCars) AND 
					im.MovementId NOT IN (SELECT * FROM deleted) AND 
					im.ItemType = 'car'
			)
			UPDATE ci
			SET IsAvailable = CASE 
				WHEN 
					lcm.MovementType IN ('incoming', 'unreserve') OR 
					lcm.MovementType = 'adjustment' AND lcm.Quantity = 1
				THEN 0
				ELSE 1
			END
			FROM CarInventory AS ci
			LEFT JOIN LastCarMovement AS lcm ON lcm.CarId = ci.CarId AND lcm.rn = 1
			WHERE ci.CarId IN (SELECT CarId FROM @AffectedCars)



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
				FROM deleted
				WHERE ItemType = 'part'
				GROUP BY PartId
			)
			UPDATE Parts
			SET Parts.Quantity -= ms.QuantityChange
			FROM Parts
			JOIN MovementSums ms ON Parts.PartId = ms.PartId;
		END
		ELSE IF CONTEXT_INFO() != 0x44454C4554455
        BEGIN
            ;THROW 50005, 'Прямое удаление из таблицы InventoryMovements запрещено, кроме случая, когда удаляется adjustment с отрицательным количеством', 1;
        END
    END
END
GO