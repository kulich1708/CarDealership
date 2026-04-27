-- Процедура трейд-ина
DROP PROCEDURE IF EXISTS usp_TradeInCar;
GO
CREATE PROCEDURE usp_TradeInCar
	@NewCarId INT,
	
	@OldCarTrimId INT,
	@OldCarColor NVARCHAR(30),
	@OldCarVin VARCHAR(17),
	@OldCarManufacturedYear INT,
	@OldCarMileage INT,
	
	@ClientId INT,
	@EmployeeId INT = NULL,

	@TradeInCarId INT OUTPUT,
	@OrderId INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TradeInValue DECIMAL(10,2);
	DECLARE @NewCarPrice DECIMAL(10,2);
	DECLARE @FinalPrice DECIMAL(10,2);
	
	
	BEGIN TRY
		BEGIN TRANSACTION;
		
		IF NOT EXISTS (SELECT 1 FROM Clients WHERE ClientId = @ClientId AND IsArchived = 0)
			THROW 50001, N'Клиент не найден или заархивирован', 1;
		
		IF NOT EXISTS (SELECT 1 FROM CarInventory WHERE CarId = @NewCarId AND IsAvailable = 1)
			THROW 50012, N'Новый автомобиль не найден или недоступен', 1;
		
		SELECT @NewCarPrice = Price FROM CarInventory WHERE CarId = @NewCarId;
		
		EXEC usp_AddCarForTradeIn 
			@TrimId = @OldCarTrimId,
			@Color = @OldCarColor,
			@Vin = @OldCarVin,
			@ManufacturedYear = @OldCarManufacturedYear,
			@Mileage = @OldCarMileage,
			@CarId = @TradeInCarId OUTPUT,
			@TradeInValue = @TradeInValue OUTPUT;
		
		SET @FinalPrice = @NewCarPrice - @TradeInValue;
		IF @FinalPrice < 0
			SET @FinalPrice = 0;
		
		-- Создание заказа на новый авто
		DECLARE @OrderItems OrderItemsType;
		INSERT INTO @OrderItems (ItemType, ItemId, Quantity, UnitPrice)
		VALUES ('car', @NewCarId, 1, @FinalPrice);
		
		EXEC usp_CreateCustomerOrder
			@ClientId = @ClientId,
			@EmployeeId = @EmployeeId,
			@Items = @OrderItems,
			@OrderId = @OrderId OUTPUT;
		
		UPDATE Orders 
		SET Status = 'completed' 
		WHERE OrderId = @OrderId;
		
		COMMIT TRANSACTION;
		
		PRINT N'Трейд-ин успешно завершен!';
		PRINT N'Оценка вашего автомобиля: ' + FORMAT(@TradeInValue, 'N2') + N' руб.';
		PRINT N'Цена нового автомобиля: ' + FORMAT(@NewCarPrice, 'N2') + N' руб.';
		PRINT N'Итоговая сумма к оплате: ' + FORMAT(@FinalPrice, 'N2') + N' руб.';
		PRINT N'Номер заказа: ' + CAST(@OrderId AS NVARCHAR(20));
		PRINT N'ID вашего автомобиля в системе: ' + CAST(@TradeInCarId AS NVARCHAR(20));
		
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorState INT = ERROR_STATE();
		
		THROW @ErrorNumber, @ErrorMessage, @ErrorState;
	END CATCH
END
GO