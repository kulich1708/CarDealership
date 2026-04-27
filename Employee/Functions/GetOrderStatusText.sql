
DROP FUNCTION IF EXISTS FN_GetOrderStatusText;
GO
CREATE FUNCTION FN_GetOrderStatusText (@Status VARCHAR(20))
RETURNS NVARCHAR(50)
AS
BEGIN
    RETURN CASE @Status
        WHEN 'pending' THEN 'В обработке'
        WHEN 'completed' THEN 'Выполнен'
        WHEN 'cancelled' THEN 'Отменен'
        ELSE 'Неизвестно'
    END
END
GO