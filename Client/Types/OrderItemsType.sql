DROP TYPE IF EXISTS OrderItemsType;
GO
CREATE TYPE OrderItemsType AS TABLE (
    ItemType VARCHAR(10) NOT NULL CHECK (ItemType IN ('car', 'part')),
    ItemId INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1 CHECK (Quantity > 0),
	UnitPrice INT NULL
);