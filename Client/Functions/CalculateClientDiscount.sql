-- Функция рассчёта скидки
DROP FUNCTION IF EXISTS FN_CalculateClientDiscount;
GO
CREATE FUNCTION FN_CalculateClientDiscount (
	@ClientId INT,
	@OrderSubtotal DECIMAL(10,2),
	@OrderDate DATE = NULL
)
RETURNS DECIMAL(10,2)
AS
BEGIN
	DECLARE @TotalDiscount DECIMAL(10,2) = 0;
	DECLARE @OrderCount INT = 0;
	DECLARE @TotalSpent DECIMAL(10,2) = 0;
	DECLARE @FirstOrderDate DATE;
	DECLARE @DaysSinceFirstOrder INT;
	DECLARE @LastOrderDate DATE;
	DECLARE @DaysSinceLastOrder INT;
	
	IF @OrderDate IS NULL
		SET @OrderDate = CAST(GETDATE() AS DATE);
	
	SELECT 
		@OrderCount = COUNT(DISTINCT OrderId),
		@TotalSpent = SUM(TotalAmount),
		@FirstOrderDate = MIN(OrderDate),
		@LastOrderDate = MAX(OrderDate)
	FROM dbo.FN_GetMyOrders(@ClientId)
	WHERE Status = 'completed';
	
	SET @DaysSinceFirstOrder = DATEDIFF(DAY, ISNULL(@FirstOrderDate, @OrderDate), @OrderDate);
	SET @DaysSinceLastOrder = DATEDIFF(DAY, ISNULL(@LastOrderDate, @OrderDate), @OrderDate);
	
	-- Cкидка за количество заказов
	DECLARE @OrderCountDiscount DECIMAL(10,2) = 0;
	
	IF @OrderCount >= 10
		SET @OrderCountDiscount = @OrderSubtotal * 0.02;
	ELSE IF @OrderCount >= 5
		SET @OrderCountDiscount = @OrderSubtotal * 0.015;
	ELSE IF @OrderCount >= 2
		SET @OrderCountDiscount = @OrderSubtotal * 0.01;
	
	-- Cкидка за сумму всех покупок
	DECLARE @TotalSpentDiscount DECIMAL(10,2) = 0;
	
	IF @TotalSpent >= 20000000
		SET @TotalSpentDiscount = @OrderSubtotal * 0.04;
	ELSE IF @TotalSpent >= 10000000
		SET @TotalSpentDiscount = @OrderSubtotal * 0.03;
	ELSE IF @TotalSpent >= 5000000
		SET @TotalSpentDiscount = @OrderSubtotal * 0.02;
	ELSE IF @TotalSpent >= 1000000
		SET @TotalSpentDiscount = @OrderSubtotal * 0.01;
	
	-- Скидка за верность
	DECLARE @LoyaltyDiscount DECIMAL(10,2) = 0;
	
	IF @DaysSinceFirstOrder >= 365 * 5
		SET @LoyaltyDiscount = @OrderSubtotal * 0.02;
	ELSE IF @DaysSinceFirstOrder >= 365 * 3
		SET @LoyaltyDiscount = @OrderSubtotal * 0.015;
	ELSE IF @DaysSinceFirstOrder >= 365
		SET @LoyaltyDiscount = @OrderSubtotal * 0.01;
	
	-- Скидка за регулярность
	DECLARE @ActivityDiscount DECIMAL(10,2) = 0;
	
	IF @OrderCount > 0 AND @DaysSinceLastOrder <= 30
		SET @ActivityDiscount = @OrderSubtotal * 0.02;
	ELSE IF @OrderCount > 0 AND @DaysSinceLastOrder <= 90
		SET @ActivityDiscount = @OrderSubtotal * 0.01;

	
	SET @TotalDiscount = @OrderCountDiscount + @TotalSpentDiscount + @LoyaltyDiscount + @ActivityDiscount;
	-- Ограничения
	IF @TotalDiscount > (@OrderSubtotal * 0.1)
		SET @TotalDiscount = @OrderSubtotal * 0.1;
	
	IF @TotalDiscount < 0
		SET @TotalDiscount = 0;
	
	RETURN ROUND(@TotalDiscount, 0);
END
GO