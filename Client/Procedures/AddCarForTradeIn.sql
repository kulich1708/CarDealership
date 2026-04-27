
-- Процедура добавления автомобиля с оценкой
DROP PROCEDURE IF EXISTS usp_AddCarForTradeIn;
GO
CREATE PROCEDURE usp_AddCarForTradeIn
	@TrimId INT,
	@Color NVARCHAR(30),
	@Vin VARCHAR(17),
	@ManufacturedYear INT,
	@Mileage INT,
	@CarId INT OUTPUT,
	@TradeInValue DECIMAL(10,2) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION;
		
		IF EXISTS (SELECT 1 FROM CarInventory WHERE Vin = @Vin)
		BEGIN
			;THROW 50010, N'Автомобиль с таким VIN уже существует', 1;
		END
		
		-- Добавление авто
		INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable)
		VALUES (@TrimId, @Color, @Vin, @ManufacturedYear, @Mileage, (SELECT BasePrice FROM CarTrims WHERE TrimId = @TrimId), 1);
		
		SET @CarId = SCOPE_IDENTITY();

		SET @TradeInValue = dbo.FN_CalculateCarCost(@CarId);
		UPDATE CarInventory
		SET Price = @TradeInValue
		WHERE CarId = @CarId;
		
		COMMIT TRANSACTION;
		
		PRINT N'Автомобиль успешно добавлен с оценкой: ' + FORMAT(@TradeInValue, 'N2') + N' руб.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		
		DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorState INT = ERROR_STATE();
		
		THROW @ErrorNumber, @ErrorMessage, @ErrorState;
	END CATCH
END
GO