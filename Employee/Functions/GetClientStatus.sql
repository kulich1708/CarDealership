DROP FUNCTION IF EXISTS FN_GetClientStatus;
GO
CREATE FUNCTION FN_GetClientStatus (@OrderCount INT)
RETURNS NVARCHAR(20)
AS
BEGIN
    IF @OrderCount >= 5 RETURN 'VIP'
    IF @OrderCount >= 2 RETURN 'Постоянный'
    RETURN 'Новый'
END
GO