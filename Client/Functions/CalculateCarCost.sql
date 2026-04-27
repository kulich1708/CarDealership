
-- Функция оценки стоимости авто
DROP FUNCTION IF EXISTS FN_CalculateCarCost;
GO
CREATE FUNCTION FN_CalculateCarCost (@CarId INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
	DECLARE @MarketPrice DECIMAL(10,2);
	DECLARE @Mileage INT;
	DECLARE @ManufacturedYear INT;
	DECLARE @TrimId INT;
	DECLARE @BaseValue DECIMAL(10,2);
	DECLARE @AgeDiscount DECIMAL(10,2);
	DECLARE @MileageDiscount DECIMAL(10,2);
	DECLARE @FinalValue DECIMAL(10,2);
	DECLARE @CurrentYear INT = YEAR(GETDATE());
	
	-- Данные авто
	SELECT 
		@Mileage = Mileage,
		@ManufacturedYear = ManufacturedYear,
		@TrimId = TrimId
	FROM CarInventory 
	WHERE CarId = @CarId;
	
	-- Базовая цена
	SELECT @MarketPrice = BasePrice
	FROM CarTrims 
	WHERE TrimId = @TrimId;
 
	IF @Mileage = 0
		RETURN @MarketPrice;
 
	SET @BaseValue = @MarketPrice * 0.7;
	
	-- Скидка за возраст
	DECLARE @CarAge INT = @CurrentYear - @ManufacturedYear;
	IF @CarAge > 15
		SET @AgeDiscount = @BaseValue * 0.3;
	ELSE IF @CarAge > 0
		SET @AgeDiscount = @BaseValue * (@CarAge * 0.02);
	ELSE
		SET @AgeDiscount = 0;
	
	-- Скидка за пробег
	DECLARE @MileageFactor DECIMAL(5,2) = @Mileage / 10000.0 * 0.005;
	IF @MileageFactor > 0.2
		SET @MileageDiscount = @BaseValue * 0.2;
	ELSE
		SET @MileageDiscount = @BaseValue * @MileageFactor;
	
	-- Итоговая стоимость
	SET @FinalValue = @BaseValue - @AgeDiscount - @MileageDiscount;
	IF @FinalValue < (@MarketPrice * 0.1)
		SET @FinalValue = @MarketPrice * 0.1;
	
	RETURN ROUND(@FinalValue, 2);
END
GO
