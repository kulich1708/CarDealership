DROP PROCEDURE IF EXISTS usp_СancellationCustomerOrder;
GO
CREATE PROCEDURE usp_СancellationCustomerOrder (@OrderId INT, @ClientId INT = NULL) AS 
BEGIN
	SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderId = @OrderId)
		THROW 50001, N'Заказ с таким номером не существует', 1;
	IF @ClientId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Orders WHERE OrderId = @OrderId AND ClientId = @ClientId) 
		THROW 50001, N'Вы не являетесь владельцем этого заказа', 1;
	UPDATE Orders
	SET Status = 'cancelled'
	WHERE OrderId = @OrderId;

	PRINT N'Заказ №' + CAST(@OrderId AS NVARCHAR(15)) + N' успешно отменён';
END
GO

