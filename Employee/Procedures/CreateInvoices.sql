-- Процедура для создания счёт-фактур клиентам
DROP PROCEDURE IF EXISTS usp_CreateInvoice;
DROP PROCEDURE IF EXISTS usp_CreateSupplierInvoice;
DROP PROCEDURE IF EXISTS usp_CreateInvoices;
DROP PROCEDURE IF EXISTS usp_CreateSupplierInvoices;
DROP PROCEDURE IF EXISTS usp_CreateInvoiceCommon;
GO

CREATE PROCEDURE usp_CreateInvoiceCommon
    @Type NVARCHAR(20),
    @ReferenceId INT,
    @IssueDate DATE = NULL,
    @DueDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Единая таблица для работы
    DECLARE @Invoices InvoiceDataCommonType;
    
    -- Заполнение из таблицы или из отдельной переменной
    INSERT INTO @Invoices (ReferenceId, IssueDate, DueDate)
    VALUES (@ReferenceId, @IssueDate, @DueDate);

	EXEC usp_CreateInvoicesCommon @TableType = @Type, @Invoices = @Invoices
	
END
GO
CREATE PROCEDURE usp_CreateInvoices (@Invoices InvoiceDataCommonType READONLY) AS
BEGIN
	SET NOCOUNT ON;
	EXEC usp_CreateInvoicesCommon 
	@TableType = 'Invoice',
	@Invoices = @Invoices
END
GO
CREATE PROCEDURE usp_CreateSupplierInvoices (@SupplierInvoices InvoiceDataCommonType READONLY) AS
BEGIN
	SET NOCOUNT ON;
	EXEC usp_CreateInvoicesCommon 
	@TableType = 'SupplierInvoice',
	@Invoices = @SupplierInvoices
END
GO
CREATE PROCEDURE usp_CreateInvoice (@InvoiceId INT, @IssueDate DATE = NULL, @DueDate DATE = NULL) AS
BEGIN
	SET NOCOUNT ON;
	EXEC usp_CreateInvoiceCommon 
	@Type = 'Invoice',
	@ReferenceId = @InvoiceId,
	@IssueDate = @IssueDate,
	@DueDate = @DueDate
END
GO
CREATE PROCEDURE usp_CreateSupplierInvoice (@SupplierInvoiceId INT, @IssueDate DATE = NULL, @DueDate DATE = NULL) AS
BEGIN
	SET NOCOUNT ON;
	EXEC usp_CreateInvoiceCommon 
	@Type = 'SupplierInvoice',
	@ReferenceId = @SupplierInvoiceId,
	@IssueDate = @IssueDate,
	@DueDate = @DueDate
END