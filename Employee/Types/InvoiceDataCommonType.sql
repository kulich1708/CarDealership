DROP TYPE IF EXISTS InvoiceDataCommonType;
CREATE TYPE InvoiceDataCommonType AS TABLE (
	ReferenceId INT,
	IssueDate DATE NULL DEFAULT NULL,
	DueDate DATE NULL
);