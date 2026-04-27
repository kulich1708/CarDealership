DROP TYPE IF EXISTS PartsToOrderType;
GO
CREATE TYPE PartsToOrderType AS TABLE (
	PartId INT,
	EmployeeId INT,
	Quantity INT,
	UnitPrice INT
);
GO