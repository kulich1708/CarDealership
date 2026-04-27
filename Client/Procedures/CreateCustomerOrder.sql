DROP PROCEDURE IF EXISTS usp_CreateCustomerOrder;
GO
CREATE PROCEDURE usp_CreateCustomerOrder
    @ClientId INT,
	@EmployeeId INT = NULL,
    @Items OrderItemsType READONLY,
	@OrderId INT OUTPUT AS 
BEGIN
	SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRANSACTION
		IF NOT EXISTS (SELECT 1 FROM Clients WHERE ClientId = @ClientId AND IsArchived = 0)
			THROW 50001, N'Клиент не найден или заархивирован', 1;
		IF NOT EXISTS (SELECT 1 FROM @Items)
			THROW 50001, N'Нет данных для создания заказа', 1;
		IF @EmployeeId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeId = @EmployeeId AND FireDate IS NULL)
		BEGIN
			SET @EmployeeId = NULL;
			PRINT(N'Сотрудник не найден, заказ будет создан без указания сотрудника');
		END

		
		INSERT INTO Orders (ClientId, EmployeeId)
		VALUES (@ClientId, @EmployeeId);
		SET @OrderId = SCOPE_IDENTITY();

		INSERT INTO OrderItems(OrderId, ItemType, CarId, Quantity, UnitPrice)
		SELECT 
		@OrderId, 'car', ci.CarId, 1, 
		CASE 
			WHEN i.UnitPrice IS NULL THEN ci.Price
			ELSE i.UnitPrice
		END
		FROM @Items AS i
		JOIN CarInventory AS ci ON ci.CarId = i.ItemId
		WHERE i.ItemType = 'car' AND ci.IsAvailable = 1;
		
		INSERT INTO OrderItems(OrderId, ItemType, PartId, Quantity, UnitPrice)
		SELECT @OrderId, 'part', p.PartId, i.Quantity, 
		CASE 
			WHEN i.UnitPrice IS NULL THEN p.Price
			ELSE i.UnitPrice
		END
		FROM @Items AS i
		JOIN Parts AS p ON p.PartId = i.ItemId
		WHERE i.ItemType = 'part' AND p.Quantity >= i.Quantity;

		IF NOT EXISTS (SELECT 1 FROM OrderItems WHERE OrderId = @OrderId)
			THROW 50001, N'Не удалось добавить ни одни товар. Проверьте доступность', 1;

		DECLARE @TotalPrice INT;
		SET @TotalPrice = (SELECT SUM(TotalPrice) FROM OrderItems WHERE OrderId = @OrderId);

		UPDATE Orders
		SET DiscountAmount = dbo.FN_CalculateClientDiscount(@ClientId, @TotalPrice, NULL)
		WHERE OrderId = @OrderId;

		PRINT N'Заказ №' + CAST(@OrderId AS NVARCHAR(15)) + N' успешно создан';
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
			DECLARE @ErrorNumber INT = ERROR_NUMBER();
			DECLARE @ErrorState INT = ERROR_STATE();
			
			THROW @ErrorNumber, @ErrorMessage, @ErrorState;
		END
	END CATCH
END
GO