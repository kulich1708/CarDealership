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
	GenerationId INT IDENTITY(1, 1) PRIMARY KEY,
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







-- Очистка данных
DELETE FROM CarInventory;
DELETE FROM CarTrims;
DELETE FROM ModelGenerations
DELETE FROM CarModels;
DELETE FROM Brands;
GO
-- Сброс IDENTITY (автоинкрементных счетчиков) для всех таблиц
DBCC CHECKIDENT ('CarInventory', RESEED, 1);
DBCC CHECKIDENT ('CarTrims', RESEED, 1);
DBCC CHECKIDENT ('CarModels', RESEED, 1);
DBCC CHECKIDENT ('Brands', RESEED, 1);
DBCC CHECKIDENT ('ModelGenerations', RESEED, 1);
GO

-- 5 брендов
INSERT INTO Brands (BrandName, Country, Description) VALUES
('Toyota', 'Япония', 'Мировой лидер по надежности, известен гибридными технологиями'),
('BMW', 'Германия', 'Немецкий премиум-бренд с акцентом на управляемость'),
('Kia', 'Южная Корея', 'Современный дизайн, длинные гарантии, хорошая оснащенность'),
('Mercedes-Benz', 'Германия', 'Эталон комфорта и статуса в автомобильном мире'),
('Lada', 'Россия', 'Доступные автомобили для российских дорог');
GO

-- Для 4 брендов по 1-3 модели
-- Toyota
INSERT INTO CarModels (BrandId, ModelName, Description) VALUES
(1, 'Camry', 'Флагманский седан, известен надежностью'),
(1, 'RAV4', 'Популярный кроссовер с полным приводом'),
(1, 'Hilux', 'Легендарный неубиваемый пикап');
GO

-- BMW
INSERT INTO CarModels (BrandId, ModelName, Description) VALUES
(2, '3 Series', 'Спортивный седан бизнес-класса'),
(2, 'X5', 'Флагманский кроссовер SAV');
GO

-- Kia
INSERT INTO CarModels (BrandId, ModelName, Description) VALUES
(3, 'Rio', 'Популярный компактный седан'),
(3, 'Sportage', 'Стильный кроссовер среднего класса'),
(3, 'K5', 'Новый флагманский седан');
GO

-- Mercedes
INSERT INTO CarModels (BrandId, ModelName, Description) VALUES
(4, 'E-Class', 'Бизнес-класс в эталонном исполнении'),
(4, 'GLE', 'Премиальный кроссовер');
GO

-- Lada: 0 моделей 

-- ========================= Поколения ==========================
-- Toyota
INSERT INTO ModelGenerations(ModelId, GenerationName, StartYear) VALUES
(1, 'XV70', 2017),
(2, 'XA50', 2018),
(3, 'AN120', 2015);
GO

-- BMW
INSERT INTO ModelGenerations(ModelId, GenerationName, StartYear) VALUES
(4, 'G20', 2018),
(5, 'G05', 2018);
GO

-- Kia
INSERT INTO ModelGenerations(ModelId, GenerationName, StartYear) VALUES
(6, 'QB', 2017),
(7, 'QL', 2015),
(8, 'DL3', 2020);
GO

-- Mercedes
INSERT INTO ModelGenerations(ModelId, GenerationName, StartYear) VALUES
(9, 'W213', 2016),
(10, 'W167', 2019);
GO
SELECT * FROM Brands;
-- ========================= Комплектации =======================

-- Toyota Camry
INSERT INTO CarTrims (GenerationId, TrimName, EnginePower, Transmission, BodyType, FuelType, DriveType, BasePrice) VALUES
(1, 'Comfort', 249, 'Автомат', 'Седан', 'Гибрид', 'Передний', 4500000),
(1, 'Prestige', 249, 'Автомат', 'Седан', 'Гибрид', 'Передний', 4500000);
GO

-- Toyota RAV4
INSERT INTO CarTrims (GenerationId, TrimName, EnginePower, Transmission, BodyType, FuelType, DriveType, BasePrice) VALUES
(2, 'Style', 150, 'Автомат', 'Кроссовер', 'Гибрид', 'Полный', 2500000),
(2, 'Prestige', 194, 'Автомат', 'Кроссовер', 'Гибрид', 'Полный', 1500000);
GO

-- BMW 3 Series
INSERT INTO CarTrims (GenerationId, TrimName, EnginePower, Transmission, BodyType, FuelType, DriveType, BasePrice) VALUES
(4, '320i', 184, 'Автомат', 'Седан', 'Бензин', 'Задний', 2000000),
(4, '330i', 249, 'Автомат', 'Седан', 'Бензин', 'Задний', 3000000),
(4, 'M340i', 374, 'Автомат', 'Седан', 'Бензин', 'Задний', 4000000);
GO

-- Kia Rio
INSERT INTO CarTrims (GenerationId, TrimName, EnginePower, Transmission, BodyType, FuelType, DriveType, BasePrice) VALUES
(6, 'Classic', 100, 'Механика', 'Седан', 'Бензин', 'Передний', 3000000),
(6, 'Comfort', 123, 'Автомат', 'Седан', 'Бензин', 'Передний', 2500000);
GO

-- Kia Sportage
INSERT INTO CarTrims (GenerationId, TrimName, EnginePower, Transmission, BodyType, FuelType, DriveType, BasePrice) VALUES
(7, 'Classic', 150, 'Механика', 'Кроссовер', 'Бензин', 'Передний', 1500000),
(7, 'Luxe', 185, 'Автомат', 'Кроссовер', 'Бензин', 'Передний', 5500000);
GO

-- Mercedes-Benz E-Class
INSERT INTO CarTrims (GenerationId, TrimName, EnginePower, Transmission, BodyType, FuelType, DriveType, BasePrice) VALUES
(9, 'E 200', 197, 'Автомат', 'Седан', 'Бензин', 'Задний', 3500000),
(9, 'E 350', 299, 'Автомат', 'Седан', 'Бензин', 'Задний', 4000000);
GO

-- Mercedes-Benz GLE
INSERT INTO CarTrims (GenerationId, TrimName, EnginePower, Transmission, BodyType, FuelType, DriveType, BasePrice) VALUES
(10, 'GLE 300 d', 245, 'Автомат', 'Кроссовер', 'Дизель', 'Полный', 3500000);


-- ========================= Конкретные авто =======================

-- Toyota Camry Comfort
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(1, 'Черный', 'JTDKB21B501234567', 2022, 0, 3100000.00, 1),
(1, 'Серый металлик', 'JTDKB21B501234568', 2023, 0, 3200000.00, 1),
(1, 'Серебристый', 'JTDKB21B501234570', 2024, 0, 3250000.00, 1),
(1, 'Синий металлик', 'JTDKB21B501234571', 2023, 8000, 3150000.00, 1);
GO

-- Toyota Camry Prestige
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(2, 'Белый жемчуг', 'JTDKB21B501234569', 2023, 5000, 3700000.00, 0),
(2, 'Черный металлик', 'JTDKB21B501234572', 2024, 0, 3850000.00, 1),
(2, 'Серый графит', 'JTDKB21B501234573', 2023, 12000, 3650000.00, 0);
GO

-- Toyota RAV4 Style
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(3, 'Белый', 'JTMFB3FV701234570', 2023, 0, 2750000.00, 1),
(3, 'Красный', 'JTMFB3FV701234571', 2024, 0, 2800000.00, 1);
GO

-- Toyota RAV4 Prestige
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(4, 'Синий', 'JTMFB3FV701234567', 2022, 20000, 3100000.00, 1),
(4, 'Белый', 'JTMFB3FV701234568', 2023, 10000, 3150000.00, 1),
(4, 'Черный', 'JTMFB3FV701234569', 2023, 0, 3200000.00, 1),
(4, 'Серебристый', 'JTMFB3FV701234572', 2024, 0, 3300000.00, 1);
GO

-- BMW 320i
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(5, 'Синий металлик', 'WBA5R1C57J1234567', 2021, 0, 4000000.00, 1),
(5, 'Черный сапфир', 'WBA5R1C57J1234568', 2022, 0, 4150000.00, 1),
(5, 'Белый', 'WBA5R1C57J1234570', 2024, 0, 4250000.00, 1),
(5, 'Серый', 'WBA5R1C57J1234571', 2023, 25000, 3950000.00, 1);
GO

-- BMW 330i
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(6, 'Синий', 'WBA5R1C57J1234572', 2023, 0, 5300000.00, 1),
(6, 'Черный', 'WBA5R1C57J1234573', 2024, 0, 5400000.00, 1),
(6, 'Белый', 'WBA5R1C57J1234574', 2022, 35000, 4950000.00, 0);
GO

-- BMW M340i
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(7, 'Красный', 'WBA5R1C57J1234569', 2023, 500, 6500000.00, 1);
GO

-- Kia Rio Classic
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(8, 'Белый', 'Z94C241ABNR123456', 2021, 40000, 1150000.00, 1),
(8, 'Серебристый', 'Z94C241ABNR123457', 2022, 0, 1180000.00, 1),
(8, 'Серый', 'Z94C241ABNR123458', 2022, 0, 1170000.00, 0),
(8, 'Синий', 'Z94C241ABNR123467', 2024, 0, 1200000.00, 1);
GO

-- Kia Sportage Classic
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(10, 'Серый', 'Z94C241ABNR123462', 2023, 0, 2150000.00, 1),
(10, 'Синий', 'Z94C241ABNR123463', 2024, 0, 2200000.00, 1);
GO

-- Kia Sportage Luxe
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(11, 'Белый', 'Z94C241ABNR123464', 2023, 0, 2550000.00, 1),
(11, 'Черный', 'Z94C241ABNR123465', 2024, 0, 2600000.00, 1),
(11, 'Красный', 'Z94C241ABNR123466', 2023, 18000, 2450000.00, 1);
GO

-- Mercedes-Benz E 200
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(12, 'Черный', 'WDD2130041A123456', 2020, 45000, 5000000.00, 1),
(12, 'Серый металлик', 'WDD2130041A123457', 2021, 0, 5100000.00, 1);
GO

-- Mercedes-Benz E 350
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(13, 'Черный', 'WDD2130041A123458', 2023, 0, 6700000.00, 1),
(13, 'Серебристый', 'WDD2130041A123459', 2024, 0, 6800000.00, 1);
GO

-- Mercedes-Benz GLE 300 d
INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable) VALUES
(14, 'Белый', 'W1N1670141A123456', 2022, 0, 7300000.00, 1),
(14, 'Черный', 'W1N1670141A123457', 2023, 0, 7600000.00, 1),
(14, 'Серый', 'W1N1670141A123458', 2024, 0, 7700000.00, 1);
GO

-- Kia Rio Comfort - комплектация есть, но машин нет








-- Очистка данных (сначала дочерние таблицы, потом родительские)
DELETE FROM PartCompatibility;
DELETE FROM Parts;
DELETE FROM Categories;
DELETE FROM Suppliers;
GO

-- Сброс IDENTITY (автоинкрементных счетчиков) для всех таблиц
DBCC CHECKIDENT ('PartCompatibility', RESEED, 1);
DBCC CHECKIDENT ('Parts', RESEED, 1);
DBCC CHECKIDENT ('Categories', RESEED, 1);
DBCC CHECKIDENT ('Suppliers', RESEED, 1);
GO

-- Поставщики
INSERT INTO Suppliers (Name, ContactPhone, Email, Address) VALUES
('АвтоДеталь Трейд', '+7(495)111-22-33', 'order@adt.ru', N'г. Москва, ул. Промышленная, д. 1'),
('Запчасти для иномарок', '+7(812)222-33-44', 'info@zap-ino.ru', N'г. Санкт-Петербург, пр. Стачек, д. 50'),
('Японские Автозапчасти', '+7(383)300-40-50', 'supply@japanparts.ru', N'г. Новосибирск, ул. Сибиряков-Гвардейцев, д. 22'),
('Германия АутоТек', '+7(343)444-55-66', 'deutsch@autotec.de', N'г. Екатеринбург, ул. Машиностроителей, д. 15'),
('ДВС и Компоненты', '+7(863)555-66-77', 'engine@dvsk.ru', N'г. Ростов-на-Дону, пр. Стачки, д. 120'),
('Тормозные Системы', '+7(846)666-77-88', 'brakes@torsystem.ru', N'г. Самара, ул. Ново-Садовая, д. 160'),
('Электрооборудование Авто', '+7(861)777-88-99', 'electro@car-ecu.ru', N'г. Краснодар, ул. Красных Партизан, д. 220'),
('Подвеска и Рулевое', '+7(391)888-99-00', 'suspension@podveska.ru', N'г. Красноярск, ул. 9 Мая, д. 75'),
('Фильтры и Масла', '+7(3812)999-00-11', 'filters@oil-filter.ru', N'г. Омск, ул. 10 лет Октября, д. 100'),
('Кузовные Детали', '+7(4722)100-20-30', 'body@kuzov.ru', N'г. Белгород, ул. Щорса, д. 42');
GO

-- Категории
INSERT INTO Categories (Name, ParentCategoryId, MinStockThreshold) VALUES
(N'Двигатель', NULL, 5),
(N'Трансмиссия', NULL, 3),
(N'Подвеска и рулевое', NULL, 7),
(N'Тормозная система', NULL, 8),
(N'Электрика и электроника', NULL, 10),
(N'Кузов и оптика', NULL, 15),
(N'Фильтры и расходники', NULL, 20),
-- Подкатегории для Двигатель
(N'Поршневая группа', 1, 2),
(N'Головка блока цилиндров (ГБЦ)', 1, 2),
(N'Система охлаждения', 1, 6),
(N'Система смазки', 1, 4),
-- Подкатегории для Трансмиссия
(N'Сцепление', 2, 4),
(N'Коробка передач (АКПП)', 2, 1),
(N'Коробка передач (МКПП)', 2, 1),
(N'Приводные валы (ШРУС)', 2, 6),
-- Подкатегории для Электрика и электроника
(N'Аккумуляторы и стартеры', 5, 5),
(N'Датчики', 5, 12),
(N'Освещение', 5, 15),
-- Подкатегории для Кузов и оптика
(N'Фары и фонари', 6, 10),
(N'Бампера и обвес', 6, 4),
(N'Лобовые стекла', 6, 2);
GO

-- Запчасти
INSERT INTO Parts (CategoryId, SupplierId, Name, Description, Price) VALUES
-- 1-5: Поршневая группа (кат. 8)
(8, 3, N'Поршень Toyota 2AR-FE', N'Поршень двигателя 2.5 л для Camry, RAV4. Алюминиевый сплав.', 8500.00),
(8, 4, N'Поршень BMW N20', N'Поршень для двигателя 2.0 Turbo. Усиленная конструкция.', 11200.00),
(8, 1, N'Кольца поршневые комплект', N'Комплект колец на 1 цилиндр. Универсальный размер.', 3200.00),
(8, 5, N'Шатун кованый', N'Кованый шатун для тюнинга. Повышенная прочность.', 8900.00),
(8, 5, N'Вкладыши коленвала ремонтные', N'Ремонтный комплект вкладышей +0.25 мм', 4300.00),

-- 6-10: ГБЦ (кат. 9)
(9, 5, N'ГБЦ в сборе Kia G4FA', N'Головка блока цилиндров 1.6 л для Rio. Б/у, проверенная.', 28500.00),
(9, 1, N'Прокладка ГБЦ Toyota оригинал', N'Оригинальная прокладка ГБЦ. Теплостойкая, многослойная.', 4200.00),
(9, 4, N'Клапан впускной', N'Впускной клапан стандартного размера. Комплект 4 шт.', 5600.00),
(9, 4, N'Распредвал BMW N52', N'Распределительный вал впускной. Оригинал.', 18700.00),
(9, 5, N'Гидрокомпенсатор', N'Гидрокомпенсатор клапанов. Универсальный, 8 шт в комплекте.', 2900.00),

-- 11-15: Система охлаждения (кат. 10)
(10, 6, N'Радиатор охлаждения Mercedes W213', N'Алюминиевый, основной радиатор. Новый.', 18700.00),
(10, 10, N'Помпа водяная BMW B48', N'Водяной насос с пластиковой крыльчаткой. Сменная.', 9400.00),
(10, 2, N'Термостат 87°C', N'Термостат открытия 87°C. Для большинства иномарок.', 2400.00),
(10, 2, N'Патрубок радиатора верхний', N'Резиновый патрубок, диаметр 32мм. Гофрированный.', 1200.00),
(10, 9, N'Охлаждающая жидкость концентрат', N'Концентрат антифриза G12++, 1 л. Красный.', 800.00),

-- 16-20: Система смазки (кат. 11)
(11, 9, N'Масляный насос Toyota 1NR-FE', N'Масляный насос для двигателей 1.3-1.5 л.', 7600.00),
(11, 4, N'Масляный фильтр Mann', N'Универсальный масляный фильтр. Высокая фильтрация.', 450.00),
(11, 9, N'Масло моторное 5W-30', N'Синтетическое моторное масло, 4 л. LongLife.', 2800.00),
(11, 5, N'Маслозаборник', N'Трубка маслозаборника с сеткой.', 3100.00),
(11, 1, N'Датчик давления масла', N'Датчик аварийного давления масла. Электрический.', 1900.00),

-- 21-25: Сцепление (кат. 12)
(12, 2, N'Комплект сцепления LUK', N'Корзина, диск, выжимной подшипник. Для VW/Audi группу.', 12500.00),
(12, 1, N'Диск сцепления Valeo', N'Ведомый диск сцепления. Керамическое покрытие.', 6700.00),
(12, 8, N'Выжимной подшипник', N'Выжимной подшипник сцепления. Универсальный.', 3200.00),
(12, 2, N'Главный цилиндр сцепления', N'Гидравлический цилиндр. С бачком.', 5400.00),
(12, 8, N'Трос сцепления', N'Трос привода сцепления. Усиленный.', 2100.00),

-- 26-30: АКПП (кат. 13)
(13, 1, N'Гидроблок АКПП Toyota Aisin 6-ст', N'Клапанная плита АКПП, с соленоидами. Восстановленный.', 41500.00),
(13, 4, N'Масло ATF ZF Lifeguard 8', N'Трансмиссионное масло для АКПП ZF 8HP, 1 литр.', 1800.00),
(13, 2, N'Масляный радиатор АКПП', N'Дополнительный радиатор охлаждения ATF.', 8900.00),
(13, 4, N'Соленоид переключения', N'Соленоид управления переключением передач.', 4500.00),
(13, 1, N'Прокладка поддона АКПП', N'Резиновая прокладка поддона АКПП.', 1700.00),

-- 31-35: Подвеска (кат. 3)
(3, 8, N'Стойка амортизатора передняя левая', N'Газомасляная стойка. С пружиной.', 6700.00),
(3, 8, N'Стойка амортизатора передняя правая', N'Газомасляная стойка. С пружиной.', 6700.00),
(3, 2, N'Рычаг нижний передний с шаровой', N'Левый, для Kia/Hyundai. Оригинальный.', 4800.00),
(3, 7, N'Сайлентблок рычага задний', N'Полиуретановый сайлентблок. Повышенная жесткость.', 1200.00),
(3, 8, N'Стяжка рулевая с наконечником', N'Рулевая тяга с наконечником. Левая резьба.', 3100.00),

-- 36-40: Тормозная система (кат. 4)
(4, 6, N'Тормозной диск вентилируемый передний', N'Диск 312мм, пара. Высококачественный чугун.', 6400.00),
(4, 6, N'Колодки тормозные керамические передние', N'Комплект на ось. Низкая пыль, тихая работа.', 3900.00),
(4, 6, N'Тормозной суппорт передний левый', N'Восстановленный суппорт. С поршнями и сальниками.', 11200.00),
(4, 6, N'Тормозной шланг передний', N'Гибкий тормозной шланг. Усиленный.', 1500.00),
(4, 6, N'Тормозная жидкость DOT 4', N'1 литр. Температура кипения 260°C.', 700.00),

-- 41-45: Электрика - Аккумуляторы (кат. 16)
(16, 7, N'Аккумулятор Varta Blue Dynamic 74Ah', N'Емкость 74 Ач, пусковой ток 680 А. Необслуживаемый.', 8200.00),
(16, 7, N'Стартер Bosch для BMW N55', N'Новый стартер с редуктором. Высокий крутящий момент.', 21400.00),
(16, 7, N'Генератор Valeo 150A', N'Генератор 150 А. С регулятором напряжения.', 18900.00),
(16, 7, N'Катушка зажигания', N'Индивидуальная катушка зажигания. Для 4-цилиндровых двигателей.', 3400.00),
(16, 7, N'Свеча зажигания иридиевая', N'Иридиевые свечи, ресурс 100 000 км. Комплект 4 шт.', 4200.00),

-- 46-50: Кузов - Оптика (кат. 19)
(19, 10, N'Фара головного света левая Kia Sportage', N'Для Sportage 2016-2020, галоген. Неоригинал.', 18700.00),
(19, 10, N'Фонарь задний левый Toyota Camry XV70', N'Светодиодный, с поворотником. Оригинал.', 14300.00),
(19, 7, N'Лампа противотуманная PSX24W', N'Желтый свет, для Mercedes. Комплект 2 шт.', 1200.00),
(19, 7, N'Лампа LED H7', N'Светодиодная лампа H7, 6000K. Комплект 2 шт.', 4500.00),
(19, 10, N'Блок-фара правая BMW 3 Series G20', N'Полный блок с линзой и поворотником. Б/у.', 32500.00);
GO


-- Связи запчастей с машинами

INSERT INTO PartCompatibility (PartId, TrimId, Notes) VALUES
-- 1. Поршень Toyota 2AR-FE - ТОЛЬКО для Toyota с двигателем 2.5 л
(1, 1, N'Для Camry Comfort 2.5 л, требуется расточка блока'),
(1, 2, N'Для Camry Prestige 2.5 л, оригинальный размер'),
(1, 3, NULL), -- RAV4 Style 2.0 л - НЕ ПОДХОДИТ
(1, 4, NULL), -- RAV4 Prestige 2.0 л - НЕ ПОДХОДИТ

-- 2. Поршень BMW N20 - для BMW с двигателем 2.0 Turbo
(2, 5, N'Для BMW 320i двигатель N20B20'),
(2, 6, N'Для BMW 330i двигатель N20B20 с другой степенью сжатия'),
(2, 7, NULL), -- M340i 3.0 л - другой двигатель

-- 3. Кольца поршневые комплект - УНИВЕРСАЛЬНЫЕ (но с ограничениями)
(3, 1, N'Стандартный размер, для ремонта двигателя'),
(3, 2, NULL),
(3, 5, N'Для BMW N20, требуется хонингование цилиндров'),
(3, 6, NULL),
(3, 8, N'Для Kia 1.6 л, ремонтный комплект'),
(3, 14, NULL),

-- 4. Шатун кованый - для тюнинга
(4, 5, N'Для тюнинга BMW 320i, повышение оборотов'),
(4, 6, N'Для BMW 330i, усиленные шатуны'),
(4, 7, N'Для M340i, для установки турбо-компрессора большего размера'),

-- 5. Вкладыши коленвала - для ремонта
(5, 1, N'Ремонтный размер +0.25, после перегрева'),
(5, 8, N'Для Kia Rio, ремонт при стуке в нижней части'),
(5, 9, N'Для Sportage, при пробеге свыше 200 000 км'),

-- 6. ГБЦ в сборе Kia G4FA - ТОЛЬКО Kia с двигателем 1.6
(6, 8, N'Для Kia Rio Classic 1.6 л, полная замена'),
(6, 14, N'Для Kia Rio Comfort 1.6 л, после гидроудара'),

-- 7. Прокладка ГБЦ Toyota - ТОЛЬКО Toyota
(7, 1, N'Оригинальная, при перегреве двигателя'),
(7, 2, NULL),
(7, 3, N'Для RAV4, профилактическая замена при ТО 100 000 км'),
(7, 4, NULL),

-- 8. Клапан впускной - для немецких авто
(8, 5, N'Для BMW, при прогаре клапанов'),
(8, 6, NULL),
(8, 11, N'Для Mercedes E 200, ремонт ГБЦ'),
(8, 12, N'Для E 350, увеличенный диаметр'),

-- 9. Распредвал BMW N52 - ТОЛЬКО старые BMW
(9, 5, N'Для BMW 320i до 2015 года'),
(9, 6, N'Для 330i с двигателем N52'),

-- 10. Гидрокомпенсатор - УНИВЕРСАЛЬНЫЕ
(10, 1, N'При стуке на холодную, комплект 8 шт.'),
(10, 2, NULL),
(10, 5, N'Для BMW, тихие гидрики'),
(10, 8, N'Для Kia, частый износ'),
(10, 11, N'Для Mercedes, оригинальные'),

-- 11. Радиатор охлаждения Mercedes - ТОЛЬКО Mercedes
(11, 11, N'Для E 200, алюминиевый с пластиковыми бачками'),
(11, 12, N'Для E 350, усиленный вариант'),
(11, 13, N'Для GLE 300 d, с масляным радиатором'),

-- 12. Помпа водяная BMW B48 - для новых BMW
(12, 5, N'Для BMW 320i после 2017 года'),
(12, 6, N'Для 330i B48 двигатель'),
(12, 7, N'Для M340i, повышенная производительность'),

-- 13. Термостат - УНИВЕРСАЛЬНЫЕ
(13, 1, N'87°C, для нормального климата'),
(13, 3, N'Для RAV4, раннее открытие'),
(13, 8, N'Для Kia Rio, термостат с быстрым прогревом'),
(13, 11, N'Для Mercedes, электронное управление'),

-- 14. Патрубок радиатора - расходник
(14, 1, N'При потрескивании или утечках'),
(14, 5, NULL),
(14, 9, N'Для Sportage, частый износ'),
(14, 13, N'Для GLE, специальный изгиб'),

-- 15. Охлаждающая жидкость - ВСЕМ
(15, 1, NULL),
(15, 2, NULL),
(15, 3, NULL),
(15, 4, NULL),
(15, 5, NULL),
(15, 6, NULL),
(15, 7, NULL),
(15, 8, NULL),
(15, 9, NULL),
(15, 10, NULL),
(15, 11, NULL),
(15, 12, NULL),
(15, 13, NULL),
(15, 14, NULL),

-- 16. Масляный насос Toyota - ТОЛЬКО Toyota
(16, 1, N'При низком давлении масла'),
(16, 2, NULL),
(16, 3, N'Для RAV4, ревизия насоса'),

-- 17. Масляный фильтр Mann - ВСЕМ (кроме особых случаев)
(17, 1, NULL),
(17, 2, NULL),
(17, 3, NULL),
(17, 4, NULL),
(17, 5, N'Для BMW, с обратным клапаном'),
(17, 8, NULL),
(17, 9, NULL),
(17, 11, NULL),
(17, 13, N'Для дизеля, усиленная фильтрация'),

-- 18. Масло моторное 5W-30 - ВСЕМ бензиновым
(18, 1, N'LongLife, замена каждые 15 000 км'),
(18, 2, NULL),
(18, 3, NULL),
(18, 4, NULL),
(18, 5, NULL),
(18, 6, NULL),
(18, 7, N'Для M340i, допуск BMW LL-04'),
(18, 8, NULL),
(18, 9, NULL),
(18, 10, NULL),
(18, 11, NULL),
(18, 12, NULL),
(18, 14, NULL),

-- 19. Маслозаборник - при ремонте
(19, 1, N'При засорении сетки'),
(19, 8, N'Для Kia Rio, изогнутая форма'),
(19, 9, N'Для Sportage, с датчиком уровня'),

-- 20. Датчик давления масла - при неисправности
(20, 1, N'При мигающей лампочке давления'),
(20, 5, N'Для BMW, частый отказ'),
(20, 11, N'Для Mercedes, с термодатчиком'),

-- 21. Комплект сцепления LUK - для VW/Audi группу (не все авто)
(21, 5, N'Для BMW с механической КПП'),
(21, 8, N'Для Kia Rio Classic (механика)'),
(21, 9, N'Для Sportage Classic (механика)'),

-- 22. Диск сцепления Valeo - альтернатива
(22, 8, N'Для Kia Rio, керамическое покрытие'),
(22, 14, N'Для Rio Comfort, мягче ход'),

-- 23. Выжимной подшипник - при шуме
(23, 1, N'При выжиме сцепления слышен шум'),
(23, 8, NULL),
(23, 9, NULL),

-- 24. Главный цилиндр сцепления - при утечке
(24, 8, N'Для Kia Rio, частые течи'),
(24, 9, N'Для Sportage, усиленный'),

-- 25. Трос сцепления - для механики
(25, 8, N'Для Rio Classic, тросовый привод'),
(25, 9, N'Для Sportage Classic, требует регулировки'),

-- 26. Гидроблок АКПП Toyota - ТОЛЬКО Toyota с АКПП
(26, 1, N'Для Camry АКПП 6 ст., ремонт пакета соленоидов'),
(26, 2, NULL),
(26, 3, N'Для RAV4, при пинках при переключении'),

-- 27. Масло ATF ZF Lifeguard 8 - для АКПП ZF
(27, 5, N'Для BMW 320i АКПП ZF 8HP'),
(27, 6, NULL),
(27, 7, NULL),
(27, 11, N'Для Mercedes 9G-TRONIC'),
(27, 12, NULL),

-- 28. Масляный радиатор АКПП - при перегреве
(28, 1, N'Для Camry, дополнительное охлаждение'),
(28, 3, N'Для RAV4, для бездорожья'),
(28, 13, N'Для GLE, интегрированный в основной радиатор'),

-- 29. Соленоид переключения - ремонт АКПП
(29, 1, N'При ошибках переключения передач'),
(29, 5, N'Для BMW, соленоид давления'),

-- 30. Прокладка поддона АКПП - при течи
(30, 1, N'При потеках масла АКПП'),
(30, 5, NULL),
(30, 11, N'Для Mercedes, резиновая с металлической вставкой'),

-- 31. Стойка амортизатора передняя левая - при износе
(31, 1, N'Замена при стуках, левая сторона'),
(31, 3, N'Для RAV4, усиленная для бездорожья'),
(31, 9, N'Для Sportage, с пружиной'),

-- 32. Стойка амортизатора передняя правая
(32, 1, N'Правая сторона, менять парой'),
(32, 3, NULL),
(32, 9, NULL),

-- 33. Рычаг нижний передний с шаровой - для Kia
(33, 8, N'Для Rio, при стуке на кочках'),
(33, 9, N'Для Sportage, усиленный вариант'),
(33, 10, N'Для Sportage Luxe, с большим ходом'),

-- 34. Сайлентблок рычага задний - полиуретан
(34, 1, N'Полиуретан, для спортивной настройки'),
(34, 5, N'Для BMW, жестче штатного'),
(34, 11, N'Для Mercedes, ресурс выше в 3 раза'),

-- 35. Стяжка рулевая - при люфте руля
(35, 1, N'При люфте руля, левая резьба'),
(35, 8, N'Для Kia Rio, частый износ'),
(35, 11, N'Для Mercedes, с защитным чехлом'),

-- 36. Тормозной диск передний - при износе/биении
(36, 1, N'Диск 312мм, вентилируемый'),
(36, 2, NULL),
(36, 5, N'Для BMW 320i, перфорированный'),
(36, 6, N'Для 330i, диаметр больше'),
(36, 11, N'Для E 200, с датчиком износа'),

-- 37. Колодки тормозные керамические - ВСЕМ
(37, 1, N'Низкая пыль, тихие'),
(37, 2, NULL),
(37, 5, NULL),
(37, 6, NULL),
(37, 8, NULL),
(37, 9, NULL),
(37, 11, NULL),
(37, 12, NULL),

-- 38. Тормозной суппорт передний левый - при заклинивании
(38, 1, N'Восстановленный, левая сторона'),
(38, 5, N'Для BMW, с плавающей скобой'),
(38, 11, N'Для Mercedes, с электронным стояночным тормозом'),

-- 39. Тормозной шланг - при износе
(39, 1, N'Гибкий, при трещинах'),
(39, 9, N'Для Sportage, для бездорожья'),
(39, 13, N'Для GLE, армированный'),

-- 40. Тормозная жидкость DOT 4 - ВСЕМ
(40, 1, NULL),
(40, 2, NULL),
(40, 3, NULL),
(40, 4, NULL),
(40, 5, NULL),
(40, 6, NULL),
(40, 7, NULL),
(40, 8, NULL),
(40, 9, NULL),
(40, 10, NULL),
(40, 11, NULL),
(40, 12, NULL),
(40, 13, NULL),
(40, 14, NULL),

-- 41. Аккумулятор Varta - ВСЕМ
(41, 1, NULL),
(41, 2, NULL),
(41, 3, NULL),
(41, 4, NULL),
(41, 5, NULL),
(41, 6, NULL),
(41, 7, N'Для M340i, повышенная емкость'),
(41, 8, NULL),
(41, 9, NULL),
(41, 10, NULL),
(41, 11, NULL),
(41, 12, NULL),
(41, 13, NULL),
(41, 14, NULL),

-- 42. Стартер Bosch для BMW - ТОЛЬКО BMW
(42, 5, N'Для 320i, с редуктором'),
(42, 6, NULL),
(42, 7, N'Для M340i, повышенная мощность'),

-- 43. Генератор Valeo 150A - для мощных авто
(43, 2, N'Для Camry Prestige с доп. оборудованием'),
(43, 7, N'Для M340i, 150А достаточно'),
(43, 12, N'Для E 350, с системой start-stop'),

-- 44. Катушка зажигания - при пропусках зажигания
(44, 1, N'При троении двигателя'),
(44, 8, N'Для Kia Rio, частый выход из строя'),
(44, 11, N'Для Mercedes, индивидуальные катушки'),

-- 45. Свеча иридиевая - ВСЕМ бензиновым
(45, 1, N'Ресурс 100 000 км'),
(45, 2, NULL),
(45, 5, NULL),
(45, 6, NULL),
(45, 7, N'Для M340i, специальный зазор'),
(45, 8, NULL),
(45, 9, NULL),
(45, 11, NULL),
(45, 12, NULL),

-- 46. Фара Kia Sportage - ТОЛЬКО Sportage
(46, 9, N'Для Sportage Classic, галоген'),
(46, 10, N'Для Sportage Luxe, подходит но лучше LED'),

-- 47. Фонарь задний Toyota Camry - ТОЛЬКО Camry
(47, 1, N'Для Camry Comfort, светодиодный'),
(47, 2, N'Для Prestige, с затемнением'),

-- 48. Лампа противотуманная - для Mercedes
(48, 11, N'Для E 200, желтый свет'),
(48, 12, NULL),
(48, 13, N'Для GLE, угол освещения шире'),

-- 49. Лампа LED H7 - для модернизации
(49, 9, N'Для Sportage, замена галогена на LED'),
(49, 10, NULL),
(49, 11, N'Для Mercedes, нужен корректор фар'),

-- 50. Блок-фара BMW 3 Series - ТОЛЬКО BMW G20
(50, 5, N'Для 320i, с линзой'),
(50, 6, N'Для 330i, та же конфигурация'),
(50, 7, N'Для M340i, отличается дизайном - уточняйте');
GO







-- Сотрудники
INSERT INTO Employees (Email, PasswordHash, FullName, Position, Phone, HireDate, FireDate) VALUES
('ivan.petrov@example.com', '$2b$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'Иван Петров', N'Менеджер', '+79990000001', '2023-01-15', NULL),
('olga.smirnova@example.com', '$2b$12$J9qoVFJFKpPrmAvxWQ7sO.BS9q8z3j4k5l6m7n8o9p0q1r2s3t4u', N'Ольга Смирнова', N'Бухгалтер', '+79990000002', '2022-08-23', NULL),
('alexey.ivanov@example.com', '$2b$12$aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789abcdefghiJKL', N'Алексей Иванов', N'Разработчик', '+79990000003', '2021-07-10', NULL),
('elena.kuznetsova@example.com', '$2b$12$xYzAbCdEfGhIjKlMnOpQrStUvWx0123456789abcdefghiJKL', N'Елена Кузнецова', N'HR', '+79990000004', '2024-02-01', NULL),
('dmitry.sokolov@example.com', '$2b$12$KmNoPqRsTuVwXyZ0123456789abcdefghiJKlMnOpQrStUvWx', N'Дмитрий Соколов', N'Системный администратор', '+79990000005', '2020-11-30', NULL),
('maria.fedorova@example.com', '$2b$12$pQrStUvWxYzAbCdEfGhIjKlMnOp0123456789abcdefghiJKL', N'Мария Федорова', N'Маркетолог', '+79990000006', '2023-05-20', NULL),
('sergey.karpov@example.com', '$2b$12$defGhIjKlMnOpQrStUvWxYzAbCdEf0123456789abcdefghiJK', N'Сергей Карпов', N'Тестировщик', '+79990000007', '2021-03-17', NULL),
('anna.volkova@example.com', '$2b$12$fGhIjKlMnOpQrStUvWxYzAbCdEfGh0123456789abcdefghiJK', N'Анна Волкова', N'Аналитик', '+79990000008', '2019-12-01', NULL),
('pavel.romanov@example.com', '$2b$12$hIjKlMnOpQrStUvWxYzAbCdEfGhIj0123456789abcdefghiJK', N'Павел Романов', N'Дизайнер', '+79990000009', '2022-07-07', NULL),
('elena.morozova@example.com', '$2b$12$jKlMnOpQrStUvWxYzAbCdEfGhIjKl0123456789abcdefghiJK', N'Елена Морозова', N'Менеджер проектов', '+79990000010', '2023-09-01', NULL);

-- Клиенты
INSERT INTO Clients (Email, PasswordHash, FullName, Phone, Address, IsArchived) VALUES
('client1@example.com', '$2b$12$kLmNoPqRsTuVwXyZAbCdEfGhIjKlMn0123456789abcdefghiJK', N'Иван Иванов', '+79161234567', N'Москва, ул. Ленина, д.1', 0),
('client2@example.com', '$2b$12$mNoPqRsTuVwXyZAbCdEfGhIjKlMnOp0123456789abcdefghiJK', N'Мария Смирнова', '+79161234568', N'Санкт-Петербург, пр. Невский, д.10', 0),
('client3@example.com', '$2b$12$nOpQrStUvWxYzAbCdEfGhIjKlMnOpQr0123456789abcdefghiJ', N'Андрей Кузнецов', '+79161234569', N'Новосибирск, ул. Советская, д.15', 0),
('client4@example.com', '$2b$12$oPqRsTuVwXyZAbCdEfGhIjKlMnOpQrS0123456789abcdefghiJ', N'Ольга Петрова', '+79161234570', N'Екатеринбург, ул. Мира, д.7', 0),
('client5@example.com', '$2b$12$pQrStUvWxYzAbCdEfGhIjKlMnOpQrSt0123456789abcdefghiJ', N'Сергей Васильев', '+79161234571', N'Казань, ул. Баумана, д.3', 0),
('client6@example.com', '$2b$12$qRsTuVwXyZAbCdEfGhIjKlMnOpQrStU0123456789abcdefghiJ', N'Татьяна Морозова', '+79161234572', N'Челябинск, ул. Кирова, д.9', 0),
('client7@example.com', '$2b$12$rStUvWxYzAbCdEfGhIjKlMnOpQrStUv0123456789abcdefghiJ', N'Алексей Новиков', '+79161234573', N'Ростов-на-Дону, пр. Будённовский, д.14', 0),
('client8@example.com', '$2b$12$sTuVwXyZAbCdEfGhIjKlMnOpQrStUvW0123456789abcdefghiJ', N'Екатерина Соколова', '+79161234574', N'Уфа, ул. Ленина, д.11', 0),
('client9@example.com', '$2b$12$tUvWxYzAbCdEfGhIjKlMnOpQrStUvWx0123456789abcdefghiJ', N'Дмитрий Павлов', '+79161234575', N'Воронеж, ул. 20 лет Октября, д.8', 0),
('client10@example.com', '$2b$12$uVwXyZAbCdEfGhIjKlMnOpQrStUvWxY0123456789abcdefghiJ', N'Анна Федорова', '+79161234576', N'Пермь, ул. Газеты Звезда, д.12', 0),
('client11@example.com', '$2b$12$vWxYzAbCdEfGhIjKlMnOpQrStUvWxYz0123456789abcdefghiJ', N'Николай Сидоров', '+79161234577', N'Волгоград, ул. Комсомольская, д.20', 0),
('client12@example.com', '$2b$12$wXyZAbCdEfGhIjKlMnOpQrStUvWxYzA0123456789abcdefghiJ', N'Марина Белова', '+79161234578', N'Красноярск, ул. Карла Маркса, д.5', 0),
('client13@example.com', '$2b$12$xYzAbCdEfGhIjKlMnOpQrStUvWxYzAb0123456789abcdefghiJ', N'Владимир Орлов', '+79161234579', N'Тольятти, ул. Коммунистическая, д.13', 0),
('client14@example.com', '$2b$12$yZAbCdEfGhIjKlMnOpQrStUvWxYzAbC0123456789abcdefghiJ', N'Елена Громова', '+79161234580', N'Ижевск, ул. Пушкинская, д.2', 0),
('client15@example.com', '$2b$12$zAbCdEfGhIjKlMnOpQrStUvWxYzAbCd0123456789abcdefghiJ', N'Константин Петров', '+79161234581', N'Барнаул, ул. Малахова, д.4', 0),
('client16@example.com', '$2b$12$AbCdEfGhIjKlMnOpQrStUvWxYzAbCdE0123456789abcdefghiJ', N'Светлана Ковалёва', '+79161234582', N'Ульяновск, ул. Генерала Тюленева, д.6', 0),
('client17@example.com', '$2b$12$BCDefGhIjKlMnOpQrStUvWxYzAbCdEf0123456789abcdefghiJ', N'Игорь Кузьмин', '+79161234583', N'Тюмень, ул. Республики, д.18', 0),
('client18@example.com', '$2b$12$CDefGhIjKlMnOpQrStUvWxYzAbCdEfG0123456789abcdefghiJ', N'Юлия Лебедева', '+79161234584', N'Ставрополь, ул. Ленина, д.21', 0),
('client19@example.com', '$2b$12$DEfGhIjKlMnOpQrStUvWxYzAbCdEfGh0123456789abcdefghiJ', N'Василий Максимов', '+79161234585', N'Нижний Новгород, ул. Рождественская, д.24', 0),
('client20@example.com', '$2b$12$EFgHiJkLmNoPqRsTuVwXyZAbCdEfGhI0123456789abcdefghiJ', N'Алина Власова', '+79161234586', N'Чебоксары, ул. Ярославская, д.28', 0);
GO



DROP FUNCTION IF EXISTS FN_ConvertPrice;
GO
CREATE FUNCTION FN_ConvertPrice(@Price INT)
RETURNS INT
BEGIN
	RETURN @Price * 80;
END
GO

-- Все заказы конкретного клиента
DROP FUNCTION IF EXISTS FN_GetMyOrders;
GO
CREATE FUNCTION FN_GetMyOrders (@ClientId INT)
RETURNS TABLE AS
RETURN (
	SELECT 
		o.OrderId,
		o.OrderDate,
		o.Status,
		COUNT(oi.OrderItemId) AS ItemsCount,
		SUM(oi.TotalPrice) AS TotalAmount,
		i.InvoiceId,
		i.DueDate
	FROM Orders o
	LEFT JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
	LEFT JOIN Invoices AS i ON o.OrderId = i.OrderId
	WHERE o.ClientId = @ClientId
	GROUP BY o.OrderId, o.OrderDate, o.Status, i.InvoiceId, i.DueDate);
GO

SELECT * FROM FN_GetMyOrders(4);
GO

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


-- Поиск запчастей по марке, модели, поколению, модификации или VIN машины
DROP PROCEDURE IF EXISTS usp_FindPartsForCar;
GO
CREATE PROCEDURE usp_FindPartsForCar(
	@Brand NVARCHAR(MAX) = NULL,
	@Model NVARCHAR(MAX) = NULL,
	@Generation NVARCHAR(MAX) = NULL,
	@Trim NVARCHAR(MAX) = NULL,
	@VIN NVARCHAR(30) = NULL
) AS
BEGIN
	SELECT
	p.Name AS PartName,
	b.BrandName,
	m.ModelName,
	g.GenerationName,
	t.TrimName,
	p.Description,
	p.Price,
	p.Quantity,
	pc.Notes,
	c.Name AS CategoryName
	FROM Parts AS p
	JOIN Categories AS c ON p.CategoryId = c.CategoryId
	JOIN PartCompatibility AS pc ON pc.PartId = p.PartId
	JOIN CarTrims AS t ON pc.TrimId = t.TrimId
	JOIN ModelGenerations AS g ON t.GenerationId = g.GenerationId
	JOIN CarModels AS m ON g.ModelId = m.ModelId
	JOIN Brands AS b ON m.BrandId = b.BrandId
	WHERE
		(@VIN IS NOT NULL AND pc.TrimId = (
			SELECT TrimId 
			FROM CarInventory AS ci 
			WHERE Vin = @VIN
		)) OR 
		(@VIN IS NULL AND
		(@Brand IS NULL OR b.BrandName = @Brand) AND
		(@Model IS NULL OR m.ModelName = @Model) AND
		(@Generation IS NULL OR g.GenerationName = @Generation) AND
		(@Trim IS NULL OR t.TrimName = @Trim));
END
GO


-- Процедура добавления автомобиля с оценкой
DROP PROCEDURE IF EXISTS usp_AddCarForTradeIn;
GO
CREATE PROCEDURE usp_AddCarForTradeIn
	@TrimId INT,
	@Color NVARCHAR(30),
	@Vin VARCHAR(17),
	@ManufacturedYear INT,
	@Mileage INT,
	@CarId INT OUTPUT,
	@TradeInValue DECIMAL(10,2) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION;
		
		IF EXISTS (SELECT 1 FROM CarInventory WHERE Vin = @Vin)
		BEGIN
			;THROW 50010, N'Автомобиль с таким VIN уже существует', 1;
		END
		
		-- Добавление авто
		INSERT INTO CarInventory (TrimId, Color, Vin, ManufacturedYear, Mileage, Price, IsAvailable)
		VALUES (@TrimId, @Color, @Vin, @ManufacturedYear, @Mileage, (SELECT BasePrice FROM CarTrims WHERE TrimId = @TrimId), 1);
		
		SET @CarId = SCOPE_IDENTITY();

		SET @TradeInValue = dbo.FN_CalculateCarCost(@CarId);
		UPDATE CarInventory
		SET Price = @TradeInValue
		WHERE CarId = @CarId;
		
		COMMIT TRANSACTION;
		
		PRINT N'Автомобиль успешно добавлен с оценкой: ' + FORMAT(@TradeInValue, 'N2') + N' руб.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		
		DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorState INT = ERROR_STATE();
		
		THROW @ErrorNumber, @ErrorMessage, @ErrorState;
	END CATCH
END
GO

DROP TYPE IF EXISTS OrderItemsType;
GO
CREATE TYPE OrderItemsType AS TABLE (
    ItemType VARCHAR(10) NOT NULL CHECK (ItemType IN ('car', 'part')),
    ItemId INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1 CHECK (Quantity > 0),
	UnitPrice INT NULL
);
DROP PROCEDURE IF EXISTS usp_CreateCustomerOrder;
GO
CREATE PROCEDURE usp_CreateCustomerOrder
    @ClientId INT,
	@EmployeeId INT = NULL,
    @Items OrderItemsType READONLY,
	@OrderId INT OUTPUT AS 
BEGIN
	SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRANSACTION
		IF NOT EXISTS (SELECT 1 FROM Clients WHERE ClientId = @ClientId AND IsArchived = 0)
			THROW 50001, N'Клиент не найден или заархивирован', 1;
		IF NOT EXISTS (SELECT 1 FROM @Items)
			THROW 50001, N'Нет данных для создания заказа', 1;
		IF @EmployeeId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeId = @EmployeeId AND FireDate IS NULL)
		BEGIN
			SET @EmployeeId = NULL;
			PRINT(N'Сотрудник не найден, заказ будет создан без указания сотрудника');
		END

		
		INSERT INTO Orders (ClientId, EmployeeId)
		VALUES (@ClientId, @EmployeeId);
		SET @OrderId = SCOPE_IDENTITY();

		INSERT INTO OrderItems(OrderId, ItemType, CarId, Quantity, UnitPrice)
		SELECT 
		@OrderId, 'car', ci.CarId, 1, 
		CASE 
			WHEN i.UnitPrice IS NULL THEN ci.Price
			ELSE i.UnitPrice
		END
		FROM @Items AS i
		JOIN CarInventory AS ci ON ci.CarId = i.ItemId
		WHERE i.ItemType = 'car' AND ci.IsAvailable = 1;
		
		INSERT INTO OrderItems(OrderId, ItemType, PartId, Quantity, UnitPrice)
		SELECT @OrderId, 'part', p.PartId, i.Quantity, 
		CASE 
			WHEN i.UnitPrice IS NULL THEN p.Price
			ELSE i.UnitPrice
		END
		FROM @Items AS i
		JOIN Parts AS p ON p.PartId = i.ItemId
		WHERE i.ItemType = 'part' AND p.Quantity >= i.Quantity;

		IF NOT EXISTS (SELECT 1 FROM OrderItems WHERE OrderId = @OrderId)
			THROW 50001, N'Не удалось добавить ни одни товар. Проверьте доступность', 1;

		DECLARE @TotalPrice INT;
		SET @TotalPrice = (SELECT SUM(TotalPrice) FROM OrderItems WHERE OrderId = @OrderId);

		UPDATE Orders
		SET DiscountAmount = dbo.FN_CalculateClientDiscount(@ClientId, @TotalPrice, NULL)
		WHERE OrderId = @OrderId;

		PRINT N'Заказ №' + CAST(@OrderId AS NVARCHAR(15)) + N' успешно создан';
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
			DECLARE @ErrorNumber INT = ERROR_NUMBER();
			DECLARE @ErrorState INT = ERROR_STATE();
			
			THROW @ErrorNumber, @ErrorMessage, @ErrorState;
		END
	END CATCH
END
GO
DROP PROCEDURE IF EXISTS usp_СancellationCustomerOrder;
GO
CREATE PROCEDURE usp_СancellationCustomerOrder (@OrderId INT, @ClientId INT = NULL) AS 
BEGIN
	SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderId = @OrderId)
		THROW 50001, N'Заказ с таким номером не существует', 1;
	IF @ClientId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Orders WHERE OrderId = @OrderId AND ClientId = @ClientId) 
		THROW 50001, N'Вы не являетесь владельцем этого заказа', 1;
	UPDATE Orders
	SET Status = 'cancelled'
	WHERE OrderId = @OrderId;

	PRINT N'Заказ №' + CAST(@OrderId AS NVARCHAR(15)) + N' успешно отменён';
END
GO


-- Процедура трейд-ина
DROP PROCEDURE IF EXISTS usp_TradeInCar;
GO
CREATE PROCEDURE usp_TradeInCar
	@NewCarId INT,
	
	@OldCarTrimId INT,
	@OldCarColor NVARCHAR(30),
	@OldCarVin VARCHAR(17),
	@OldCarManufacturedYear INT,
	@OldCarMileage INT,
	
	@ClientId INT,
	@EmployeeId INT = NULL,

	@TradeInCarId INT OUTPUT,
	@OrderId INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TradeInValue DECIMAL(10,2);
	DECLARE @NewCarPrice DECIMAL(10,2);
	DECLARE @FinalPrice DECIMAL(10,2);
	
	
	BEGIN TRY
		BEGIN TRANSACTION;
		
		IF NOT EXISTS (SELECT 1 FROM Clients WHERE ClientId = @ClientId AND IsArchived = 0)
			THROW 50001, N'Клиент не найден или заархивирован', 1;
		
		IF NOT EXISTS (SELECT 1 FROM CarInventory WHERE CarId = @NewCarId AND IsAvailable = 1)
			THROW 50012, N'Новый автомобиль не найден или недоступен', 1;
		
		SELECT @NewCarPrice = Price FROM CarInventory WHERE CarId = @NewCarId;
		
		EXEC usp_AddCarForTradeIn 
			@TrimId = @OldCarTrimId,
			@Color = @OldCarColor,
			@Vin = @OldCarVin,
			@ManufacturedYear = @OldCarManufacturedYear,
			@Mileage = @OldCarMileage,
			@CarId = @TradeInCarId OUTPUT,
			@TradeInValue = @TradeInValue OUTPUT;
		
		SET @FinalPrice = @NewCarPrice - @TradeInValue;
		IF @FinalPrice < 0
			SET @FinalPrice = 0;
		
		-- Создание заказа на новый авто
		DECLARE @OrderItems OrderItemsType;
		INSERT INTO @OrderItems (ItemType, ItemId, Quantity, UnitPrice)
		VALUES ('car', @NewCarId, 1, @FinalPrice);
		
		EXEC usp_CreateCustomerOrder
			@ClientId = @ClientId,
			@EmployeeId = @EmployeeId,
			@Items = @OrderItems,
			@OrderId = @OrderId OUTPUT;
		
		UPDATE Orders 
		SET Status = 'completed' 
		WHERE OrderId = @OrderId;
		
		COMMIT TRANSACTION;
		
		PRINT N'Трейд-ин успешно завершен!';
		PRINT N'Оценка вашего автомобиля: ' + FORMAT(@TradeInValue, 'N2') + N' руб.';
		PRINT N'Цена нового автомобиля: ' + FORMAT(@NewCarPrice, 'N2') + N' руб.';
		PRINT N'Итоговая сумма к оплате: ' + FORMAT(@FinalPrice, 'N2') + N' руб.';
		PRINT N'Номер заказа: ' + CAST(@OrderId AS NVARCHAR(20));
		PRINT N'ID вашего автомобиля в системе: ' + CAST(@TradeInCarId AS NVARCHAR(20));
		
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorState INT = ERROR_STATE();
		
		THROW @ErrorNumber, @ErrorMessage, @ErrorState;
	END CATCH
END
GO

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

DROP TYPE IF EXISTS InvoiceDataCommonType;
CREATE TYPE InvoiceDataCommonType AS TABLE (
	ReferenceId INT,
	IssueDate DATE NULL DEFAULT NULL,
	DueDate DATE NULL
);

DROP TYPE IF EXISTS PartsToOrderType;
GO
CREATE TYPE PartsToOrderType AS TABLE (
	PartId INT,
	EmployeeId INT,
	Quantity INT,
	UnitPrice INT
);
GO

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
GO

DROP PROCEDURE IF EXISTS usp_CreateSupplierOrders;
GO
CREATE PROCEDURE usp_CreateSupplierOrders(@PartsToOrder PartsToOrderType READONLY) AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS (SELECT 1 FROM @PartsToOrder)
		THROW 50001, N'Нет данных для создания заказа поставщику', 1;

	-- Таблица, В которую запишутся соответствия id поставщика и id заказа
    DECLARE @NewOrders TABLE (
        SupplierOrderId INT,
        SupplierId INT,
		EmployeeId INT
    );

	-- Создаём по 1 заказу, на каждого нужного поставщика и записываем эти данные в NewOrders
    INSERT INTO SupplierOrders (SupplierId, EmployeeId)
    OUTPUT inserted.SupplierOrderId, inserted.SupplierId , inserted.EmployeeId
    INTO @NewOrders
    SELECT DISTINCT p.SupplierId, pto.EmployeeId
    FROM @PartsToOrder AS pto
	JOIN Parts AS p ON pto.PartId = p.PartId;
	
	-- Создаём все необходимые позиции для заказов
    INSERT INTO SupplierOrderItems (SupplierOrderId, PartId, Quantity, UnitCost)
    SELECT
        no.SupplierOrderId,
        pto.PartId,
        pto.Quantity, 
        pto.UnitPrice
    FROM @PartsToOrder AS pto
	JOIN Parts AS p ON p.PartId = pto.PartId
    JOIN @NewOrders AS no ON no.SupplierId = p.SupplierId AND no.EmployeeId = pto.EmployeeId OR no.EmployeeId IS NULL;
END
GO


-- Создание заказа поставщику
DROP PROCEDURE IF EXISTS usp_CreateSupplierOrder;
GO
CREATE PROCEDURE usp_CreateSupplierOrder (@PartId INT, @EmployeeId INT = NULL, @Quantity INT, @UnitPrice INT) AS 
BEGIN
	SET NOCOUNT ON;
	IF (SELECT SupplierId FROM Parts WHERE PartId = @PartId) IS NULL
	BEGIN
		PRINT N'У товара ' + CAST(@PartId AS NVARCHAR(10)) + N' не указан поставщик, поэтому заказать его не получится.';
		RETURN;
	END
	DECLARE @PartsToOrder PartsToOrderType;
	INSERT INTO @PartsToOrder (PartId, EmployeeId, Quantity, UnitPrice)
	VALUES(@PartId, @EmployeeId, @Quantity, @UnitPrice);

	EXEC usp_CreateSupplierOrders @PartsToOrder = @PartsToOrder;
END
GO

-- Представление по продажам запчастей
DROP VIEW IF EXISTS VW_TopSellingParts;
GO
CREATE VIEW VW_TopSellingParts AS
SELECT 
    p.PartId,
    p.Name AS [Название запчасти],
    c.Name AS [Категория],
    (SELECT Name FROM Categories WHERE CategoryId = cat.ParentCategoryId) AS [Родительская категория],
    s.Name AS [Поставщик],
    SUM(oi.Quantity) AS [Продано шт],
    SUM(oi.TotalPrice) AS [Общая выручка],
    AVG(oi.UnitPrice) AS [Средняя цена],
    COUNT(DISTINCT o.ClientId) AS [Уникальных покупателей],
    AVG(oi.Quantity) AS [Среднее количество в заказе]
FROM Orders AS o
JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
JOIN Parts AS p ON oi.PartId = p.PartId
JOIN Categories AS c ON p.CategoryId = c.CategoryId
JOIN Categories AS cat ON p.CategoryId = cat.CategoryId
JOIN Suppliers AS s ON p.SupplierId = s.SupplierId
WHERE o.Status = 'completed'
  AND oi.ItemType = 'part'
GROUP BY 
    p.PartId,
    p.Name, 
    c.Name,
    cat.ParentCategoryId,
    s.Name;
GO

-- Представление по продажам авто
DROP VIEW IF EXISTS VW_TopSellingCars;
GO
CREATE VIEW VW_TopSellingCars AS
SELECT 
    b.BrandName AS [Марка],
    m.ModelName AS [Модель],
    g.GenerationName AS [Поколение],
    ct.TrimName AS [Комплектация],
	CASE 
		WHEN ci.Mileage > 0 THEN 'БУ'
		WHEN ci.Mileage = 0 THEN 'Новый'
	END AS [Состояние],
    COUNT(*) AS [Продано шт],
    SUM(oi.TotalPrice) AS [Общая выручка],
    AVG(oi.UnitPrice) AS [Средняя цена],
    COUNT(DISTINCT o.ClientId) AS [Уникальных покупателей],
    AVG(oi.Quantity) AS [Среднее количество в заказе]
FROM Orders AS o
JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
JOIN CarInventory AS ci ON oi.CarId = ci.CarId
JOIN CarTrims AS ct ON ci.TrimId = ct.TrimId
JOIN ModelGenerations AS g ON ct.GenerationId = g.GenerationId
JOIN CarModels AS m ON g.ModelId = m.ModelId
JOIN Brands AS b ON m.BrandId = b.BrandId
WHERE o.Status = 'completed'
	AND oi.ItemType = 'car'
GROUP BY 
    b.BrandName, 
    m.ModelName, 
    g.GenerationName, 
    ct.TrimName,
    CASE 
        WHEN ci.Mileage > 0 THEN 'БУ'
        WHEN ci.Mileage = 0 THEN 'Новый'
    END;;
GO


-- Отчет по продажам 
GO
DROP PROCEDURE IF EXISTS usp_GetSalesReport;
GO
CREATE PROCEDURE usp_GetSalesReport
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;
    IF @StartDate IS NULL SET @StartDate = DATEADD(MONTH, -1, GETDATE());
    IF @EndDate IS NULL SET @EndDate = GETDATE();
    
    -- Общая статистика
    SELECT 
        'Общая статистика' AS ReportType,
        COUNT(DISTINCT o.OrderId) AS OrdersCount,
        COUNT(DISTINCT o.ClientId) AS UniqueClients,
        SUM(oi.TotalPrice) AS TotalRevenue,
        AVG(oi.TotalPrice) AS AverageOrder
    FROM Orders AS o
    JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
    WHERE CAST(o.OrderDate AS DATE) BETWEEN @StartDate AND @EndDate AND
		o.Status = 'completed';
	PRINT @StartDate
	PRINT @EndDate
    
    -- Продажи по типам товаров
    SELECT 
        'По типам товаров' AS ReportType,
        oi.ItemType,
        COUNT(*) AS ItemsSold,
        SUM(oi.Quantity) AS TotalQuantity,
        SUM(oi.TotalPrice) AS Revenue
    FROM Orders AS o
    JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
    WHERE CAST(o.OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
      AND o.Status = 'completed'
    GROUP BY oi.ItemType;
    
    -- Топ товаров
    SELECT * FROM VW_TopSellingCars;
    SELECT * FROM VW_TopSellingParts;
	SELECT 
	CONCAT(Марка, Модель, Поколение, Комплектация) AS [Название],
	Состояние AS Категория,
	'Авто' AS [Родительская категория],
	[Продано шт],
	[Общая выручка],
	[Средняя цена],
	[Уникальных покупателей],
	[Среднее количество в заказе]
	FROM VW_TopSellingCars AS tsc
	UNION
	SELECT 
	[Название запчасти] AS [Название],
	Категория,
	[Родительская категория],
	[Продано шт],
	[Общая выручка],
	[Средняя цена],
	[Уникальных покупателей],
	[Среднее количество в заказе]
	FROM VW_TopSellingParts AS tsp
	ORDER BY [Общая выручка];
END
GO

-- Представление всех клиентов
DROP VIEW IF EXISTS VW_ClientsStatus;
GO
CREATE VIEW VW_ClientsStatus AS
SELECT 
    c.FullName AS ClientName,
    c.Email AS ClientEmail,
	dbo.FN_GetClientStatus(COUNT(o.OrderId)) AS Status
FROM Orders AS o
RIGHT JOIN Clients AS c ON o.ClientId = c.ClientId
WHERE c.IsArchived = 0
GROUP BY c.ClientId, c.FullName, c.Email
GO
SELECT * FROM VW_ClientsStatus
-- Представление всех заказов
DROP VIEW IF EXISTS VW_AllOrders;
GO
CREATE VIEW VW_AllOrders AS
SELECT 
    o.OrderId,
    o.OrderDate,
    dbo.FN_GetOrderStatusText(o.Status) AS Status,
    c.FullName AS ClientName,
    c.Email AS ClientEmail,
    e.FullName AS ManagerName,
    COUNT(oi.OrderItemId) AS ItemsCount,
    SUM(oi.TotalPrice) AS TotalAmount,
    i.InvoiceId,
    i.IssueDate AS InvoiceDate
FROM Orders AS o
JOIN Clients AS c ON o.ClientId = c.ClientId
LEFT JOIN Employees AS e ON o.EmployeeId = e.EmployeeId
LEFT JOIN OrderItems AS oi ON o.OrderId = oi.OrderId
LEFT JOIN Invoices AS i ON o.OrderId = i.OrderId
GROUP BY o.OrderId, o.OrderDate, o.Status, c.FullName, c.Email, 
         e.FullName, i.InvoiceId, i.IssueDate;
GO






DROP TRIGGER IF EXISTS TR_Cars_Delete
GO
CREATE TRIGGER TR_Cars_Delete
ON CarInventory INSTEAD OF DELETE AS 
BEGIN 
	SET NOCOUNT ON;
	DECLARE @OriginalContext VARBINARY(128) = CONTEXT_INFO();
	DECLARE @AllowDelete VARBINARY(128) = 0x44454C455445;
    SET CONTEXT_INFO @AllowDelete;

	BEGIN TRY
		
		BEGIN TRANSACTION;
		DELETE FROM InventoryMovements
		WHERE CarId IN (SELECT CarId FROM deleted);

		DELETE FROM OrderItems
		WHERE CarId IN (SELECT CarId FROM deleted);

		DELETE FROM CarInventory
		WHERE CarId IN (SELECT CarId FROM deleted);
	
		COMMIT TRANSACTION;

        SET CONTEXT_INFO @OriginalContext;
	END TRY
	BEGIN CATCH
		SET CONTEXT_INFO @OriginalContext;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
	END CATCH
END
GO

-- Триггеры на добавление машин
DROP TRIGGER IF EXISTS TR_CarInventory_Movements;
GO
CREATE TRIGGER TR_CarInventory_Movements
ON CarInventory FOR INSERT AS
BEGIN
	INSERT INTO InventoryMovements (ItemType, CarId, Quantity, MovementType)
	SELECT 'car', CarId, 1, 'incoming'
	FROM inserted
END
GO

DROP TRIGGER IF EXISTS TR_Clients_Delete
GO
CREATE TRIGGER TR_Clients_Delete
ON Clients INSTEAD OF DELETE AS 
BEGIN 
	SET NOCOUNT ON;
	
    BEGIN TRY
		BEGIN TRANSACTION;
		DELETE FROM Orders
		WHERE ClientId IN (SELECT ClientId FROM deleted);
		
		DELETE FROM Clients
		WHERE ClientId IN (SELECT ClientId FROM deleted);
	
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

DROP TRIGGER IF EXISTS TR_InventoryMovements_Insert
GO
CREATE TRIGGER TR_InventoryMovements_Insert
ON InventoryMovements
FOR INSERT
AS
BEGIN
	-- Пересматриваем статус машины
	UPDATE ci
	SET IsAvailable = CASE 
		WHEN 
			inserted.MovementType IN ('incoming', 'unreserve') OR 
			inserted.MovementType = 'adjustment' AND inserted.Quantity = 1
		THEN 1
		ELSE 0
	END
	FROM CarInventory AS ci
	JOIN inserted ON ci.CarId = inserted.CarId
	WHERE inserted.ItemType = 'car';


	-- Пересчитываем количество товара
	WITH MovementSums AS (
		SELECT 
			PartId,
			SUM(CASE
				WHEN MovementType IN ('incoming', 'unreserve', 'adjustment')
					THEN Quantity
				WHEN MovementType IN ('reserve')
					THEN -Quantity
				ELSE 0
			END) as QuantityChange
		FROM inserted
		WHERE ItemType = 'part'
		GROUP BY PartId
	)
	UPDATE Parts
	SET Parts.Quantity += ms.QuantityChange
	FROM Parts
	JOIN MovementSums ms ON Parts.PartId = ms.PartId;
END
GO

-- Протестирован
DROP TRIGGER IF EXISTS TR_InventoryMovements_Update
GO
CREATE TRIGGER TR_InventoryMovements_Update
ON InventoryMovements
FOR UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(ItemType) 
        OR UPDATE(PartId) 
        OR UPDATE(CarId) 
        OR UPDATE(MovementType) 
        OR UPDATE(Quantity)
        OR UPDATE(OrderItemId) 
        OR UPDATE(SupplierOrderItemId) AND (SELECT SupplierOrderItemId FROM inserted) IS NOT NULL
        OR UPDATE(MovementDate)
    BEGIN
        ;THROW 50000, N'Изменять можно олько EmployeeId и Notes. Другие поля неизменяемы.', 1;
    END
END
GO


DROP TRIGGER IF EXISTS TR_OrderItems_Delete;
GO
CREATE TRIGGER TR_OrderItems_Delete
ON OrderItems INSTEAD OF DELETE
AS 
BEGIN 
	SET NOCOUNT ON;
	
	DECLARE @OriginalContext VARBINARY(128) = CONTEXT_INFO();
	DECLARE @AllowDelete VARBINARY(128) = 0x44454C455445;
    SET CONTEXT_INFO @AllowDelete;

	BEGIN TRY
		DELETE FROM InventoryMovements
		WHERE OrderItemId IN (SELECT OrderItemId FROM deleted);

        SET CONTEXT_INFO @OriginalContext;
	END TRY
	BEGIN CATCH
		SET CONTEXT_INFO @OriginalContext;
		THROW;
	END CATCH

	DELETE FROM OrderItems
	WHERE OrderItemId IN (SElECT OrderItemId FROM deleted);
END
GO

DROP TRIGGER IF EXISTS TR_OrderItems_Insert;
GO
CREATE TRIGGER TR_OrderItems_Insert
ON OrderItems
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1
	FROM inserted
	JOIN Orders ON inserted.OrderId = Orders.OrderId
	WHERE Status != 'pending')
	BEGIN
		ROLLBACK;
		THROW 50003, N'Запрещено добавление товаров в заказ со статусом не "pending". ВНИМАНИЕ: Из-за ошибки не добавилась ни одна запись', 1;
	END

	
	-- Проверка на доступность такого количества товара
	IF EXISTS(
	SELECT 1
	FROM (SELECT PartId, SUM(Quantity) AS Quantity
	FROM inserted
	GROUP BY PartId) AS i
	JOIN Parts ON Parts.PartId = i.PartId
	WHERE Parts.Quantity < i.Quantity)
	BEGIN
		ROLLBACK;
		THROW 50004, N'Недостаточно деталей на складе.', 1;
	END
	
	-- Пересчитываем количество машин
	IF (SELECT MAX(Quantity)
	FROM (
		SELECT 
			SUM(Quantity) as Quantity
		FROM inserted
		WHERE ItemType = 'car'
		GROUP BY carId
	) AS d) > 1
	BEGIN
		ROLLBACK;
		THROW 50005, N'Нельзя добавить более одной одинаковой машины в один заказ.', 1;
	END

	-- Проверка на доступность машины
	IF EXISTS(SELECT 1
	FROM inserted
	JOIN CarInventory AS Cars ON Cars.CarId = inserted.CarId
	WHERE IsAvailable = 0)
	BEGIN
		ROLLBACK;
		THROW 50006, N'Нельзя добавить машину, которой нет в наличии.', 1;
	END
	
	
	-- Резервируем, если статус заказа в работе
	INSERT INTO InventoryMovements(
	ItemType, PartId, CarId, Quantity, 
	OrderItemId, MovementType)
	SELECT
	ItemType, PartId, CarId, Quantity, 
	inserted.OrderItemId, 'reserve'
	FROM inserted
	JOIN Orders ON inserted.OrderId = Orders.OrderId
	WHERE Orders.Status IN ('pending');
	
END

GO

DROP TRIGGER IF EXISTS TR_OrderItems_Update;
GO
CREATE TRIGGER TR_OrderItems_Update
ON OrderItems INSTEAD OF UPDATE
AS 
BEGIN 
	SET NOCOUNT ON;
	THROW 50005, 'Запрещено изменение товаров входящих в заказ. Для изменения удалите и создайте новый OrderItem', 1;
END
GO

DROP TRIGGER IF EXISTS TR_InventoryMovements_Delete
GO
CREATE TRIGGER TR_InventoryMovements_Delete
ON InventoryMovements
FOR DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Проверяем, установлен ли специальный флаг разрешения 0x44454C455445
        IF CONTEXT_INFO() = 0x44454C455445 OR
			NOT EXISTS (SELECT 1 FROM deleted WHERE MovementType != 'adjustment' OR MovementType = 'adjustment' AND Quantity > 0)
		BEGIN
			DECLARE @AffectedParts TABLE (PartId INT);
			DECLARE @AffectedCars TABLE (CarId INT);
    
			INSERT INTO @AffectedParts (PartId)
			SELECT DISTINCT PartId FROM deleted WHERE PartId IS NOT NULL;
    
			INSERT INTO @AffectedCars (CarId)
			SELECT DISTINCT CarId FROM deleted WHERE CarId IS NOT NULL;
			
			WITH LastCarMovement AS (
				SELECT 
				im.CarId,
				im.MovementId,
				im.MovementType,
				im.Quantity,
				ROW_NUMBER() OVER (
					PARTITION BY im.CarId 
					ORDER BY im.MovementDate DESC, im.MovementId DESC
				) as rn
				FROM InventoryMovements AS im
				WHERE im.CarId IN (SELECT CarId FROM @AffectedCars) AND 
					im.MovementId NOT IN (SELECT MovementId FROM deleted) AND 
					im.ItemType = 'car'
			)
			UPDATE ci
			SET IsAvailable = CASE 
				WHEN 
					lcm.MovementType IN ('incoming', 'unreserve') OR 
					lcm.MovementType = 'adjustment' AND lcm.Quantity = 1
				THEN 0
				ELSE 1
			END
			FROM CarInventory AS ci
			LEFT JOIN LastCarMovement AS lcm ON lcm.CarId = ci.CarId AND lcm.rn = 1
			WHERE ci.CarId IN (SELECT CarId FROM @AffectedCars);



			-- Пересчитываем количество товара
			WITH MovementSums AS (
				SELECT 
					PartId,
					SUM(CASE
						WHEN MovementType IN ('incoming', 'unreserve', 'adjustment')
							THEN Quantity
						WHEN MovementType IN ('reserve')
							THEN -Quantity
						ELSE 0
					END) as QuantityChange
				FROM deleted
				WHERE ItemType = 'part'
				GROUP BY PartId
			)
			UPDATE Parts
			SET Parts.Quantity -= ms.QuantityChange
			FROM Parts
			JOIN MovementSums ms ON Parts.PartId = ms.PartId;
		END
		ELSE IF CONTEXT_INFO() != 0x44454C4554455
        BEGIN
            ;THROW 50005, 'Прямое удаление из таблицы InventoryMovements запрещено, кроме случая, когда удаляется adjustment с отрицательным количеством', 1;
        END
    END
END
GO


DROP TRIGGER IF EXISTS TR_Parts_Delete
GO
CREATE TRIGGER TR_Parts_Delete
ON Parts INSTEAD OF DELETE AS 
BEGIN 
	SET NOCOUNT ON;
	
    BEGIN TRY
		BEGIN TRANSACTION;
		DELETE FROM InventoryMovements
		WHERE PartId IN (SELECT PartId FROM deleted);

		DELETE FROM OrderItems
		WHERE PartId IN (SELECT PartId FROM deleted);
		
		DELETE FROM SupplierOrderItems
		WHERE PartId IN (SELECT PartId FROM deleted);

		DELETE FROM Parts
		WHERE PartId IN (SELECT PartId FROM deleted);
	
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

DROP TRIGGER IF EXISTS TR_Parts_CheckQuantity;
GO
CREATE TRIGGER TR_Parts_CheckQuantity
ON Parts
FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON

	IF UPDATE(CategoryId) OR UPDATE(Quantity)
	BEGIN
        DECLARE @PartsToOrder PartsToOrderType;
		INSERT INTO @PartsToOrder (PartId, Quantity, UnitPrice)
		SELECT PartId, c.MinStockThreshold, Price * 0.8
        FROM inserted AS i
        JOIN Categories AS c ON i.CategoryId = c.CategoryId
        WHERE i.Quantity <= c.MinStockThreshold 
			AND i.IsReordered = 0 AND i.SupplierId IS NOT NULL;

		IF EXISTS (SELECT 1 FROM @PartsToOrder)
			EXEC usp_CreateSupplierOrders @PartsToOrder = @PartsToOrder;
	END
END
GO


DROP TRIGGER IF EXISTS TR_Orders_Delete;
GO
CREATE TRIGGER TR_Orders_Delete
ON Orders INSTEAD OF DELETE AS
BEGIN
	SET NOCOUNT ON;
	
    BEGIN TRY
		BEGIN TRANSACTION;
		DELETE FROM OrderItems
		WHERE OrderId IN (SELECT OrderId FROM deleted);

		DELETE FROM Orders
		WHERE OrderId IN (SELECT OrderId FROM deleted);
	
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

DROP TRIGGER IF EXISTS TR_Orders_Insert;
GO
CREATE TRIGGER TR_Orders_Insert
ON Orders
FOR INSERT
AS
BEGIN
	IF EXISTS (SELECT 1
	FROM inserted
	WHERE Status != 'pending')
	BEGIN
		ROLLBACK;
		THROW 50001, N'Запрещено добавление заказов со статусом не "pending". ВНИМАНИЕ: Из-за ошибки не добавилась ни одна запись', 1;
	END
END
GO

DROP TRIGGER IF EXISTS TR_Orders_UpdateStatus;
GO
CREATE TRIGGER TR_Orders_UpdateStatus
ON Orders
FOR UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF UPDATE(Status)
	BEGIN
		IF EXISTS (SELECT 1
		FROM deleted
		JOIN inserted ON deleted.OrderId = inserted.OrderId
		WHERE 
		deleted.Status IN ('completed', 'cancelled')
			AND deleted.Status != inserted.Status)
		BEGIN
			ROLLBACK;
			THROW 50002, N'Запрещено менять статус заказа с "completed" или с "cancelled". ВНИМАНИЕ: Из-за ошибки не обновилась ни одна запись', 1;
		END

		-- Отменяем резервирование, если статус заказа закрыт
		INSERT INTO InventoryMovements(
		ItemType, PartId, CarId, Quantity, 
		OrderItemId, MovementType)
		SELECT
		ItemType, PartId, CarId, Quantity, 
		OrderItemId, 'unreserve'
		FROM inserted
		JOIN deleted ON inserted.OrderId = deleted.OrderId
		JOIN OrderItems ON inserted.OrderId = OrderItems.OrderId
		WHERE inserted.Status = 'cancelled'
			AND deleted.Status != inserted.Status;

		-- Выдаём, если статус заказа выполнен
		INSERT INTO InventoryMovements(
		ItemType, PartId, CarId, Quantity, 
		OrderItemId, MovementType)
		SELECT
		ItemType, PartId, CarId, Quantity, 
		OrderItemId, 'outgoing'
		FROM inserted
		JOIN deleted ON inserted.OrderId = deleted.OrderId
		JOIN OrderItems ON inserted.OrderId = OrderItems.OrderId
		WHERE inserted.Status IN ('completed')
			AND deleted.Status != inserted.Status;

		-- Вызываем процедуру для создания счёт-фактур для всех завершённых заказов
		DECLARE @InvoiceData InvoiceDataCommonType;
		INSERT INTO @InvoiceData
		SELECT inserted.OrderId, NULL, NULL
		FROM inserted
		JOIN deleted ON inserted.OrderId = deleted.OrderId
		WHERE inserted.Status = ('completed')
			AND deleted.Status != inserted.Status;
		EXEC usp_CreateInvoices @InvoiceData;
	END
END
GO


DROP PROCEDURE IF EXISTS usp_ResetReorderStatus;
GO
DROP TYPE IF EXISTS PartsIdType;
CREATE TYPE PartsIdType AS TABLE (PartId INT);
GO
CREATE PROCEDURE usp_ResetReorderStatus(@PartsId PartsIdType READONLY) AS 
BEGIN 
	SET NOCOUNT ON;
	
	-- Устанавливаем всем поставленным товарам статус не перезаказаны, если других заказов с этими товарами нет
	UPDATE Parts
	SET IsReordered = 0
	FROM Parts p
	WHERE p.PartId IN (SELECT * FROM @PartsId)
	  AND NOT EXISTS (
		  SELECT 1
		  FROM SupplierOrderItems soi
		  JOIN SupplierOrders so ON so.SupplierOrderId = soi.SupplierOrderId
		  WHERE soi.PartId = p.PartId
			AND so.Status != 'completed'
			AND so.Status != 'cancelled'
	  );
END
GO

DROP TRIGGER IF EXISTS TR_SupplierOrderItems_Delete;
GO
CREATE TRIGGER TR_SupplierOrderItems_Delete
ON SupplierOrderItems FOR DELETE
AS 
BEGIN 
	SET NOCOUNT ON;
	-- Запускаем процедуру для правильной расстановки статусов перезаказа
	DECLARE @PartsIdTable PartsIdType;
	INSERT INTO @PartsIdTable (PartId)
	SELECT DISTINCT PartId FROM deleted;
	EXEC usp_ResetReorderStatus @PartsId = @PartsIdTable
END
GO

DROP TRIGGER IF EXISTS TR_SupplierOrderItems_Insert;
GO
CREATE TRIGGER TR_SupplierOrderItems_Insert
ON SupplierOrderItems
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1
	FROM inserted
	JOIN SupplierOrders ON inserted.SupplierOrderId = SupplierOrders.SupplierOrderId
	WHERE Status != 'pending')
	BEGIN
		ROLLBACK;
		THROW 50008, N'Запрещено добавление товаров в заказ поставщику со статусом не "pending". ВНИМАНИЕ: Из-за ошибки не добавилась ни одна запись', 1;
	END
	

	UPDATE Parts
	SET IsReordered = 1
	FROM Parts
	JOIN inserted ON Parts.PartId = inserted.PartId
	WHERE Parts.IsReordered = 0;
END
GO

-- Протестирован
DROP TRIGGER IF EXISTS TR_SupplierOrderItems_Update;
GO
CREATE TRIGGER TR_SupplierOrderItems_Update
ON SupplierOrderItems INSTEAD OF UPDATE
AS 
BEGIN 
	SET NOCOUNT ON;
	THROW 50009, 'Запрещено изменение товаров входящих в заказ поставщику. Для изменения удалите и создайте новый OrderItem', 1;
END
GO


DROP TRIGGER IF EXISTS TR_Suppliers_Delete
GO
CREATE TRIGGER TR_Suppliers_Delete
ON Suppliers INSTEAD OF DELETE AS 
BEGIN 
	SET NOCOUNT ON;
	
    BEGIN TRY
		BEGIN TRANSACTION;
		DELETE FROM SupplierOrders
		WHERE SupplierId IN (SELECT SupplierId FROM deleted);
		
		DELETE FROM Suppliers
		WHERE SupplierId IN (SELECT SupplierId FROM deleted);
	
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO



DROP TRIGGER IF EXISTS TR_SupplierOrders_Delete;
GO
CREATE TRIGGER TR_SupplierOrders_Delete
ON SupplierOrders INSTEAD OF DELETE
AS 
BEGIN 
	SET NOCOUNT ON;
	
    BEGIN TRY
		BEGIN TRANSACTION;
		DELETE FROM SupplierOrderItems
		WHERE SupplierOrderId IN (SELECT SupplierOrderId FROM deleted);

		DELETE FROM SupplierOrders
		WHERE SupplierOrderId IN (SELECT SupplierOrderId FROM deleted);
	
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


DROP TRIGGER IF EXISTS TR_SupplierOrders_Insert;
GO
CREATE TRIGGER TR_SupplierOrders_Insert
ON SupplierOrders
FOR INSERT
AS
BEGIN
	IF EXISTS (SELECT 1
	FROM inserted
	WHERE Status != 'pending')
	BEGIN
		ROLLBACK;
		THROW 50006, N'Запрещено добавление заказов поставщикам со статусом не "pending". ВНИМАНИЕ: Из-за ошибки не добавилась ни одна запись', 1;
	END
END
GO

DROP TRIGGER IF EXISTS TR_SupplierOrders_UpdateStatus;
GO
CREATE TRIGGER TR_SupplierOrders_UpdateStatus
ON SupplierOrders
FOR UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF UPDATE(Status)
	BEGIN
		IF EXISTS (SELECT 1
		FROM deleted
		JOIN inserted ON deleted.SupplierOrderId = inserted.SupplierOrderId
		WHERE 
		deleted.Status IN ('completed', 'cancelled'))
		BEGIN
			ROLLBACK;
			THROW 50007, N'Запрещено менять статус заказа с "completed" или с "cancelled". ВНИМАНИЕ: Из-за ошибки не обновилась ни одна запись', 1;
		END

		SELECT
		PartId, Quantity, 
		SupplierOrderItemId, Status
		INTO #SupplierOrderItems
		FROM inserted
		JOIN SupplierOrderItems ON inserted.SupplierOrderId = SupplierOrderItems.SupplierOrderId
		WHERE inserted.Status IN ('completed', 'cancelled');

		-- Получаем, если статус заказа выполнен
		INSERT INTO InventoryMovements(
		ItemType, PartId, Quantity, 
		SupplierOrderItemId, MovementType)
		SELECT
		'part', PartId, Quantity, 
		SupplierOrderItemId, 'incoming'
		FROM #SupplierOrderItems
		WHERE Status = 'completed';

		-- Запускаем процедуру для правильной расстановки статусов перезаказа
		DECLARE @PartsIdTable PartsIdType;
		INSERT INTO @PartsIdTable (PartId)
		SELECT PartId FROM #SupplierOrderItems;
		EXEC usp_ResetReorderStatus @PartsId = @PartsIdTable

		-- Вызываем процедуру для создания счёт-фактур для всех завершённых заказов
		DECLARE @InvoiceData InvoiceDataCommonType;
		INSERT INTO @InvoiceData
		SELECT SupplierOrderId, NULL, NULL
		FROM inserted
		WHERE inserted.Status = ('completed');
		EXEC usp_CreateSupplierInvoices @InvoiceData;
	END
END
GO
