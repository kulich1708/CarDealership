CREATE TABLE Clients(
  ClientId INT IDENTITY(1, 1) PRIMARY KEY,
  Email VARCHAR(100) UNIQUE NOT NULL,
  PasswordHash VARCHAR(255) NOT NULL,
  FullName NVARCHAR(100) NOT NULL,
  Phone VARCHAR(20) NULL,
  Address NVARCHAR(MAX) NULL,
  IsArchived BIT NOT NULL DEFAULT 0
)
GO

CREATE TABLE Employees(
  EmployeeId INT IDENTITY(1, 1) PRIMARY KEY,
  Email VARCHAR(100) UNIQUE NOT NULL,
  PasswordHash VARCHAR(255) NOT NULL,
  FullName NVARCHAR(100) NOT NULL,
  Position NVARCHAR(50) NOT NULL,
  Phone VARCHAR(20) NULL,
  HireDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
  FireDate DATE NULL
)
GO

CREATE TABLE Suppliers (
  SupplierId INT IDENTITY(1, 1) PRIMARY KEY,
  Name NVARCHAR(100) NOT NULL,
  ContactPhone VARCHAR(20) NULL,
  Email VARCHAR(100) NULL,
  Address NVARCHAR(MAX) NULL
)
GO

CREATE TABLE Categories (
  CategoryId INT IDENTITY(1, 1) PRIMARY KEY,
  Name NVARCHAR(50) NOT NULL,
  ParentCategoryId INT NULL,
  MinStockThreshold INT NOT NULL DEFAULT 5 CHECK (MinStockThreshold >= 0),
)
GO
ALTER TABLE Categories 
ADD CONSTRAINT FK_Categories_Parent 
FOREIGN KEY (ParentCategoryId) REFERENCES Categories(CategoryId);
GO
ALTER TABLE Categories
ADD CONSTRAINT CK_Categories_ParentNotSelf
CHECK (ParentCategoryId != CategoryId OR ParentCategoryId IS NULL);
GO

CREATE TABLE Brands (
  BrandId INT IDENTITY(1, 1) PRIMARY KEY,
  BrandName NVARCHAR(50) UNIQUE NOT NULL,
  Country NVARCHAR(50) NULL,
  Description NVARCHAR(MAX) NULL
)
GO

CREATE TABLE CarModels (
  ModelId INT IDENTITY(1, 1) PRIMARY KEY,
  BrandId INT NOT NULL,
  ModelName NVARCHAR(50) NOT NULL,
  Description NVARCHAR(MAX) NULL
)
GO

ALTER TABLE CarModels 
ADD CONSTRAINT FK_CarModels_BrandId
FOREIGN KEY (BrandId) REFERENCES Brands(BrandId);

CREATE TABLE ModelGenerations (
	GenerationId INT IDENTITY PRIMARY KEY,
    ModelId INT NOT NULL,
    GenerationName NVARCHAR(50) NOT NULL, 
    StartYear INT NOT NULL,
    EndYear INT NULL
)

ALTER TABLE ModelGenerations 
ADD CONSTRAINT FK_ModelGenerations_ModelId
FOREIGN KEY (ModelId) REFERENCES CarModels(ModelId);


GO

CREATE TABLE CarTrims (
  TrimId INT IDENTITY(1, 1) PRIMARY KEY,
  GenerationId INT NOT NULL,
  TrimName NVARCHAR(50) NOT NULL,
  EnginePower INT NOT NULL DEFAULT 100,
  Transmission NVARCHAR(20) NOT NULL DEFAULT 'Автомат',
  BodyType NVARCHAR(30) NOT NULL DEFAULT 'Седан',
  FuelType NVARCHAR(20) NOT NULL DEFAULT 'Бензин',
  DriveType NVARCHAR(20) NOT NULL DEFAULT 'Передний',
  BasePrice DECIMAL(10, 2) NOT NULL
)

ALTER TABLE CarTrims 
ADD CONSTRAINT FK_CarTrims_GenerationId
FOREIGN KEY (GenerationId) REFERENCES ModelGenerations(GenerationId);

GO

CREATE TABLE CarInventory (
  CarId INT IDENTITY(1, 1) PRIMARY KEY,
  TrimId INT NOT NULL,
  Color NVARCHAR(30) NOT NULL DEFAULT 'Белый',
  Vin VARCHAR(17) UNIQUE NOT NULL,
  ManufacturedYear INT NOT NULL DEFAULT 2025,
  Mileage INT NOT NULL DEFAULT 0 CHECK (Mileage >= 0),
  Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
  IsAvailable BIT NOT NULL DEFAULT 1,
  FOREIGN KEY (TrimId) REFERENCES CarTrims(TrimId)
)
GO

CREATE TABLE Parts (
  PartId INT IDENTITY(1, 1) PRIMARY KEY,
  CategoryId INT NOT NULL,
  SupplierId INT NULL,
  Name NVARCHAR(100) NOT NULL,
  Description NVARCHAR(MAX) NULL,
  Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
  Quantity INT NOT NULL CHECK (Quantity >= 0),
  IsReordered BIT DEFAULT 0,
  FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
  FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId)
)
ALTER TABLE Parts
ADD CONSTRAINT DF_Parts_Quantity
DEFAULT 0 FOR Quantity;

ALTER TABLE Parts 
ADD CONSTRAINT FK_Parts_SupplierId
FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId)
ON DELETE SET NULL;
GO

CREATE TABLE PartCompatibility (
  CompatibilityId INT IDENTITY(1, 1) PRIMARY KEY,
  PartId INT NOT NULL,
  TrimId INT NOT NULL,
  Notes NVARCHAR(MAX) NULL
)
ALTER TABLE PartCompatibility 
ADD CONSTRAINT FK_PartCompatibility_PartId
FOREIGN KEY (PartId) REFERENCES Parts(PartId)
ON DELETE CASCADE;

ALTER TABLE PartCompatibility 
ADD CONSTRAINT FK_PartCompatibility_TrimId
FOREIGN KEY (TrimId) REFERENCES CarTrims(TrimId)
ON DELETE CASCADE;


GO

CREATE TABLE Orders (
  OrderId INT IDENTITY(1, 1) PRIMARY KEY,
  ClientId INT NOT NULL,
  EmployeeId INT NULL,
  OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
  Status VARCHAR(20) NOT NULL DEFAULT 'pending'
	CHECK (Status IN ('pending', 'completed', 'cancelled')),
  DiscountAmount INT DEFAULT 0
)

ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_ClientId
FOREIGN KEY (ClientId) REFERENCES Clients(ClientId);

ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_Employees 
FOREIGN KEY (EmployeeId) 
REFERENCES Employees(EmployeeId)
ON DELETE SET NULL;
GO

GO
CREATE TABLE OrderItems (
  OrderItemId INT IDENTITY(1,1) PRIMARY KEY,
  OrderId INT NOT NULL,
  ItemType VARCHAR(10) NOT NULL CHECK (ItemType IN ('car', 'part')),
  PartId INT NULL UNIQUE,
  CarId INT NULL UNIQUE,
  Quantity INT DEFAULT 1 CHECK (Quantity > 0),
  UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0), 
  TotalPrice AS (UnitPrice * Quantity)
)
GO


ALTER TABLE OrderItems
ADD CONSTRAINT FK_OrderItem_OrderId
FOREIGN KEY (OrderId) REFERENCES Orders(OrderId);

ALTER TABLE OrderItems
ADD CONSTRAINT FK_OrderItem_PartId
FOREIGN KEY (PartId) REFERENCES Parts(PartId);

ALTER TABLE OrderItems
ADD CONSTRAINT FK_OrderItem_CarId
FOREIGN KEY (CarId) REFERENCES CarInventory(CarId);

ALTER TABLE OrderItems
ADD CONSTRAINT CK_OrderItems_ItemType
CHECK (
(ItemType = 'car' AND CarId IS NOT NULL AND PartId IS NULL AND Quantity = 1) OR
(ItemType = 'part' AND CarId IS NULL AND PartId IS NOT NULL))

CREATE TABLE Invoices (
  InvoiceId INT IDENTITY(1, 1) PRIMARY KEY,
  OrderId INT NOT NULL UNIQUE,
  IssueDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
  DueDate DATE NOT NULL
)

ALTER TABLE Invoices
ADD CONSTRAINT FK__Invoices__OrderId
FOREIGN KEY (OrderId) REFERENCES Orders(OrderId)
ON DELETE CASCADE;
GO

CREATE TABLE SupplierOrders (
  SupplierOrderId INT IDENTITY(1, 1) PRIMARY KEY,
  SupplierId INT NOT NULL,
  EmployeeId INT NULL,
  OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
  ExpectedDeliveryDate DATE NULL,
  Status VARCHAR(20) DEFAULT 'pending'
	CHECK (Status IN ('pending', 'completed', 'cancelled'))
)
ALTER TABLE SupplierOrders
ADD CONSTRAINT FK_SupplierOrders_Employees 
FOREIGN KEY (EmployeeId) 
REFERENCES Employees(EmployeeId)
ON DELETE SET NULL;
GO

ALTER TABLE SupplierOrders
ADD CONSTRAINT FK_SupplierOrders_Suppliers
FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierID);

CREATE TABLE SupplierOrderItems (
  SupplierOrderItemId INT IDENTITY(1, 1) PRIMARY KEY,
  SupplierOrderId INT NOT NULL,
  PartId INT NOT NULL,
  Quantity INT NOT NULL CHECK (Quantity > 0),
  UnitCost DECIMAL(10,2) NOT NULL CHECK (UnitCost >= 0),
)
GO
ALTER TABLE SupplierOrderItems
ADD CONSTRAINT FK_SupplierOrderItems_SupplierOrders
FOREIGN KEY (SupplierOrderId) REFERENCES SupplierOrders(SupplierOrderId);

ALTER TABLE SupplierOrderItems
ADD CONSTRAINT FK_SupplierOrderItems_Parts
FOREIGN KEY (PartId) REFERENCES Parts(PartId);

CREATE TABLE SupplierInvoices (
  InvoiceId INT IDENTITY(1, 1) PRIMARY KEY,
  SupplierOrderId INT NOT NULL UNIQUE,
  IssueDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
  DueDate DATE NOT NULL,
  FOREIGN KEY (SupplierOrderId) REFERENCES SupplierOrders(SupplierOrderId)
)
ALTER TABLE SupplierInvoices 
ADD CONSTRAINT FK_SupplierInvoices_SupplierOrderId
FOREIGN KEY (SupplierOrderId) REFERENCES SupplierOrders(SupplierOrderId)
ON DELETE CASCADE;

GO

CREATE TABLE InventoryMovements (
  MovementId INT IDENTITY(1, 1) PRIMARY KEY,
  ItemType VARCHAR(10) NOT NULL CHECK (ItemType IN ('part', 'car')),
  PartId INT NULL,
  CarId INT NULL,
  MovementType VARCHAR(20) NOT NULL DEFAULT 'adjustment'
	CHECK (MovementType IN ('incoming', 'outgoing', 'adjustment', 'reserve', 'unreserve')),
  Quantity INT NOT NULL,
  SupplierOrderItemId INT NULL,
  OrderItemId INT NULL,
  EmployeeId INT NULL,
  MovementDate DATETIME NOT NULL DEFAULT GETDATE(),
  Notes NVARCHAR(MAX) NULL,
  FOREIGN KEY (CarId) REFERENCES CarInventory(CarId),
  FOREIGN KEY (PartId) REFERENCES Parts(PartId)
)
ALTER TABLE InventoryMovements
ADD CONSTRAINT FK_InventoryMovements_Employees 
FOREIGN KEY (EmployeeId) 
REFERENCES Employees(EmployeeId)
ON DELETE SET NULL;
GO
ALTER TABLE InventoryMovements 
ADD CONSTRAINT FK_InventoryMovements_OrderItemId
FOREIGN KEY (OrderItemId) REFERENCES OrderItems(OrderItemId)
GO
ALTER TABLE InventoryMovements 
ADD CONSTRAINT FK_InventoryMovements_SupplierOrderItemId
FOREIGN KEY (SupplierOrderItemId) REFERENCES SupplierOrderItems(SupplierOrderItemId)
ON DELETE SET NULL;
GO

ALTER TABLE InventoryMovements
ADD CONSTRAINT CK_InventoryMovements_ItemType
CHECK (
(ItemType = 'car' AND CarId IS NOT NULL AND PartId IS NULL) OR
(ItemType = 'part' AND CarId IS NULL AND PartId IS NOT NULL))
GO

ALTER TABLE InventoryMovements
ADD CONSTRAINT CK_InventoryMovements_Quantity
CHECK (
(ItemType = 'part' AND MovementType != 'adjustment' AND Quantity > 0) OR
(ItemType = 'part' AND MovementType = 'adjustment' AND Quantity <> 0) OR
(ItemType = 'car' AND MovementType != 'adjustment' AND Quantity = 1) OR 
(ItemType = 'car' AND MovementType = 'adjustment' AND (Quantity = 1 OR Quantity = -1)))
GO
ALTER TABLE InventoryMovements
ADD CONSTRAINT CK_InventoryMovements_MovementType
CHECK (
(MovementType = 'incoming' AND OrderItemId IS NULL AND EmployeeId IS NULL) OR
(MovementType = 'adjustment' AND SupplierOrderItemId IS NULL AND OrderItemId IS NULL) OR 
((MovementType = 'outgoing' OR MovementType = 'reserve' OR MovementType = 'unreserve')
AND SupplierOrderItemId IS NULL AND OrderItemId IS NOT NULL AND EmployeeId IS NULL))