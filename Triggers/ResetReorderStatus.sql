DROP PROCEDURE IF EXISTS usp_ResetReorderStatus;
GO
DROP TYPE IF EXISTS PartsIdType;
CREATE TYPE PartsIdType AS TABLE (PartId INT);
GO
CREATE PROCEDURE usp_ResetReorderStatus(@PartsId PartsIdType READONLY) AS 
BEGIN 
	SET NOCOUNT ON;
	
	-- Устанавливаем всем поставленным товарам статус не перезаказаны, если других заказов с этими товарами нет
	UPDATE Parts
	SET IsReordered = 0
	FROM Parts p
	WHERE p.PartId IN (SELECT * FROM @PartsId)
	  AND NOT EXISTS (
		  SELECT 1
		  FROM SupplierOrderItems soi
		  JOIN SupplierOrders so ON so.SupplierOrderId = soi.SupplierOrderId
		  WHERE soi.PartId = p.PartId
			AND so.Status != 'completed'
			AND so.Status != 'cancelled'
	  );
END
GO