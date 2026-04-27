DROP PROCEDURE IF EXISTS usp_CreateInvoicesCommon;
GO
CREATE PROCEDURE usp_CreateInvoicesCommon
    @TableType NVARCHAR(20),
    @Invoices InvoiceDataCommonType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM @Invoices)
    BEGIN
        PRINT N'Нет данных для создания счетов';
        RETURN;
    END
		
	-- Найдём все индексы заказов, на которые добавляется более 1 счёт-фактуры
	DECLARE @OrderIdsForMany NVARCHAR(MAX) = '';
	SELECT @OrderIdsForMany = ISNULL(STRING_AGG(CAST(ReferenceId AS VARCHAR(10)), ', '), '')
	FROM (
		SELECT ReferenceId
		FROM @Invoices 
		GROUP BY ReferenceId
		HAVING COUNT(*) > 1
	) AS duplicates;

	DECLARE @NameForId NVARCHAR(20);
	SET @NameForId = 
		CASE @TableType
			WHEN 'Invoice' THEN 'OrderId'
			WHEN 'SupplierInvoice' THEN 'SupplierOrderId'
		END
	IF @OrderIdsForMany != ''
		PRINT N'Невозможно создать сразу несколько счёт фактур для заказов с ' + @NameForId + ': ' + @OrderIdsForMany + N'. Счёт фактура для этих заказов не создалась вообще. Пересмотрите добавление.';	
		
	DECLARE @OrderIdsNotCompleted NVARCHAR(MAX) = '';
	DECLARE @OrderIdsWithInvoices NVARCHAR(MAX) = '';
	IF @TableType = 'Invoice'
	BEGIN
		-- Найдём все индексы заказов, которые ещё не выполнены
		SELECT @OrderIdsNotCompleted = ISNULL(STRING_AGG(CAST(d.ReferenceId AS VARCHAR(10)), ','), '')
		FROM @Invoices AS d
		JOIN Orders AS o ON o.OrderId = d.ReferenceId
		WHERE o.Status != 'completed';


		-- Найдём все индексы заказов, у которых уже есть счёт-фактуры
		SELECT @OrderIdsWithInvoices = ISNULL(STRING_AGG(CAST(d.ReferenceId AS VARCHAR(10)), ','), '')
		FROM @Invoices AS d
		WHERE EXISTS(
			SELECT 1 FROM Invoices AS i
			WHERE i.OrderId = d.ReferenceId);

		IF @OrderIdsWithInvoices != ''
			PRINT N'Уже есть счёт фактуры для заказов с OrderId: ' + @OrderIdsWithInvoices;
		IF @OrderIdsNotCompleted != ''
			PRINT N'Невозможно создать счёт фактуры для невыполненых заказов с OrderId: ' + @OrderIdsNotCompleted;

		-- Создаём только нужные счёт фактуры
		INSERT INTO Invoices (OrderId, IssueDate, DueDate)
		SELECT d.ReferenceId,
		ISNULL(d.IssueDate, CAST(GETDATE() AS DATE)),
		ISNULL(d.DueDate, DATEADD(DAY, 30, ISNULL(d.IssueDate, CAST(GETDATE() AS DATE))))
		FROM @Invoices AS d
		JOIN Orders AS o ON o.OrderId = d.ReferenceId
		WHERE o.Status = 'completed'
			AND NOT EXISTS (
				SELECT 1 FROM Invoices AS i
				WHERE i.OrderId = d.ReferenceId) 
			AND NOT EXISTS (
				SELECT 1
				FROM @Invoices AS j 
				WHERE j.ReferenceId = d.ReferenceId 
				GROUP BY j.ReferenceId
				HAVING COUNT(*) > 1
			)
	END
	ELSE IF @TableType = 'SupplierInvoice'
	BEGIN
		-- Найдём все индексы заказов, которые ещё не выполнены
		SELECT @OrderIdsNotCompleted = ISNULL(STRING_AGG(CAST(d.ReferenceId AS VARCHAR(10)), ','), '')
		FROM @Invoices AS d
		JOIN SupplierOrders AS o ON o.SupplierOrderId = d.ReferenceId
		WHERE o.Status != 'completed';


		-- Найдём все индексы заказов, у которых уже есть счёт-фактуры
		SELECT @OrderIdsWithInvoices = ISNULL(STRING_AGG(CAST(d.ReferenceId AS VARCHAR(10)), ','), '')
		FROM @Invoices AS d
		WHERE EXISTS(
		SELECT 1 FROM SupplierInvoices AS i
		WHERE i.SupplierOrderId = d.ReferenceId);

		IF @OrderIdsWithInvoices != ''
			PRINT N'Уже есть счёт фактуры для заказов с SupplierOrderId: ' + @OrderIdsWithInvoices;
		IF @OrderIdsNotCompleted != ''
			PRINT N'Невозможно создать счёт фактуры для невыполненых заказов с SupplierOrderId: ' + @OrderIdsNotCompleted;

		-- Создаём только нужные счёт фактуры
		INSERT INTO SupplierInvoices (SupplierOrderId, IssueDate, DueDate)
		SELECT d.ReferenceId,
		ISNULL(d.IssueDate, CAST(GETDATE() AS DATE)),
		ISNULL(d.DueDate, DATEADD(DAY, 30, ISNULL(d.IssueDate, CAST(GETDATE() AS DATE))))
		FROM @Invoices AS d
		JOIN SupplierOrders AS o ON o.SupplierOrderId = d.ReferenceId
		WHERE o.Status = 'completed'
			AND NOT EXISTS (
				SELECT 1 FROM SupplierInvoices AS i
				WHERE i.SupplierOrderId = d.ReferenceId) 
			AND NOT EXISTS (
				SELECT 1
				FROM @Invoices AS j 
				WHERE j.ReferenceId = d.ReferenceId 
				GROUP BY j.ReferenceId
				HAVING COUNT(*) > 1
			)
	END
	
END
GO