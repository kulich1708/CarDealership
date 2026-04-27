-- Данные в начальное положение 
UPDATE Parts
SET Quantity = 0;
UPDATE Parts
SET IsReordered = 0;
UPDATE Parts
SET SupplierId = (SELECT MIN(SupplierId) FROM Suppliers)
WHERE SupplierId IS NULL;
UPDATE CarInventory
SET IsAvailable = 1
WHERE CarId <= 3;
DECLARE @OriginalContext VARBINARY(128) = CONTEXT_INFO();
DECLARE @Context VARBINARY(128) = 0x44454C4554455;
SET CONTEXT_INFO @Context;
DELETE FROM InventoryMovements;
SET CONTEXT_INFO @OriginalContext;
DBCC CHECKIDENT('InventoryMovements', RESEED, 0);
DELETE FROM Invoices;
DBCC CHECKIDENT('Invoices', RESEED, 0);
DELETE FROM SupplierInvoices;
DBCC CHECKIDENT('SupplierInvoices', RESEED, 0);
DELETE FROM OrderItems;
DBCC CHECKIDENT('OrderItems', RESEED, 0);
DELETE FROM Orders;
DBCC CHECKIDENT('Orders', RESEED, 0);
DELETE FROM SupplierOrderItems;
DBCC CHECKIDENT('SupplierOrderItems', RESEED, 0);
DELETE FROM SupplierOrders;
DBCC CHECKIDENT('SupplierOrders', RESEED, 0);

SELECT * FROM Orders;
SELECT * FROM OrderItems;
SELECT * FROM SupplierOrders;
SELECT * FROM SupplierOrderItems;
SELECT * FROM InventoryMovements;
SELECT * FROM Parts;
SELECT * FROM Categories;
GO
-- ============= Тест таблиц SupplierOrders и SupplierOrderItems и их связь с таблицами товаров и склада =================
-- Тест ручной вставки заказов поставщикам
INSERT INTO SupplierOrders (SupplierId, EmployeeId)
VALUES (4, 4), (5, 4);

-- Несколько одинаковых позиций в один заказ
INSERT INTO SupplierOrderItems(SupplierOrderId, PartId, Quantity, UnitCost)
VALUES (1, 3, 5, 1000), (1, 4, 5, 1000), (2, 3, 5, 1000), (2, 4, 5, 1000), (1, 3, 5, 1000), (1, 4, 5, 1000), (2, 3, 5, 1000), (2, 4, 5, 1000);

-- Один из заказов выполнен
UPDATE SupplierOrders
SET Status = 'completed'
WHERE SupplierOrderId = 1

-- Смотрим на изменение заказов, их позиций, движений на складе и количества
SELECT TOP 5 * FROM SupplierOrders ORDER BY SupplierOrderId
SELECT TOP 10 * FROM SupplierOrderItems ORDER BY SupplierOrderItemId
SELECT TOP 15 * FROM InventoryMovements ORDER BY MovementId DESC
SELECT TOP 5 * FROM Parts

-- В итоге в Parts видим количество 1 и 2 товаров 10 и при этом статус перезаказа всё ещё 1, так как есть незавершённый второй заказ

-- Второй заказ закрыт
UPDATE SupplierOrders
SET Status = 'cancelled'
WHERE SupplierOrderId = 2

-- Смотрим на изменение движений на складе и количества товаров
SELECT TOP 15 * FROM InventoryMovements ORDER BY MovementId DESC
SELECT TOP 5 * FROM Parts
-- В итоге в Parts видим количество товаров не изменилось и статус перезаказа 0
GO


-- ================= Тест ручного взаимодействия с пользовательскими заказами ========================
-- Попытка добавления заказа с неверным статусом
INSERT INTO Orders (ClientId, EmployeeId, Status)
VALUES (3, 5, 'cancelled'), (3, 5, 'pending');

-- Добавляем заказы
INSERT INTO Orders (ClientId, EmployeeId, Status)
VALUES (3, 5, 'pending'), (4, 6, 'pending');

-- Несогласованный тип позиции
INSERT INTO OrderItems (OrderId, ItemType, PartId, CarId, Quantity, UnitPrice)
VALUES (1, 'car', 3, NULL, 2, 5000000);
-- Слишком большое количество 
INSERT INTO OrderItems (OrderId, ItemType, PartId, CarId, Quantity, UnitPrice)
VALUES (1, 'part', 3, NULL, 5, 1000), (1, 'part', 4, NULL, 6, 1000);
-- Добавление двух одинаковых машин
INSERT INTO OrderItems (OrderId, ItemType, PartId, CarId, Quantity, UnitPrice)
VALUES (1, 'car', NULL, 3, 1, 5000000), (1, 'car', NULL, 3, 1, 5000000);
-- Добавление двух одинаковых машин
INSERT INTO OrderItems (OrderId, ItemType, PartId, CarId, Quantity, UnitPrice)
VALUES (1, 'car', NULL, 2, 2, 5000000);

-- Добавляем позиции в заказ
INSERT INTO OrderItems (OrderId, ItemType, PartId, CarId, Quantity, UnitPrice)
VALUES 
	(1, 'car', NULL, 3, 1, 1000000), (1, 'part', 4, NULL, 10, 1000),
	(2, 'car', NULL, 4, 1, 1000000), (2, 'part', 5, NULL, 10, 1000);

-- Смотрим на изменение заказов, их позиций, движений на складе и количества
SELECT TOP 2 * FROM Orders ORDER BY OrderId
SELECT TOP 8 * FROM OrderItems ORDER BY OrderItemId
SELECT TOP 5 * FROM SupplierOrders ORDER BY SupplierOrderId
SELECT TOP 18 * FROM SupplierOrderItems ORDER BY SupplierOrderItemId
SELECT TOP 10 * FROM InventoryMovements ORDER BY MovementId DESC
SELECT TOP 2 * FROM Parts
SELECT TOP 2 * FROM CarInventory

SELECT 0 AS Изменяем_статус_первого_заказа_на_выполненый
-- Изменяем статус заказа на выполненый
UPDATE Orders
SET Status = 'completed'
WHERE OrderId = 1

-- Смотрим на изменение заказов, их позиций, движений на складе и количества
SELECT TOP 2 * FROM Orders ORDER BY OrderId
SELECT TOP 8 * FROM OrderItems ORDER BY OrderItemId
SELECT TOP 15 * FROM InventoryMovements ORDER BY MovementId DESC
SELECT TOP 4 * FROM Parts
SELECT TOP 4 * FROM CarInventory

SELECT 0 AS Изменяем_статус_второго_заказа_на_закрытый
-- Второй заказ закрыт
UPDATE Orders
SET Status = 'cancelled'
WHERE OrderId = 2

-- Смотрим на изменение заказов, их позиций, движений на складе и количества
SELECT TOP 2 * FROM Orders ORDER BY OrderId
SELECT TOP 8 * FROM OrderItems ORDER BY OrderItemId
SELECT TOP 4 * FROM SupplierOrders ORDER BY SupplierOrderId
SELECT TOP 15 * FROM SupplierOrderItems ORDER BY SupplierOrderItemId
SELECT TOP 10 * FROM InventoryMovements ORDER BY MovementId DESC
SELECT TOP 2 * FROM Parts
SELECT * FROM Categories
SELECT TOP 2 * FROM CarInventory

-- Корректировка остатков
INSERT INTO InventoryMovements(ItemType, PartId, Quantity, EmployeeId)
VALUES ('part', 2, -5, 1);

SELECT TOP 10 * FROM InventoryMovements ORDER BY MovementId DESC
SELECT TOP 2 * FROM Parts
GO


-- =============== Базовые правильные вставки заказов для поставщиков и клиентов
-- Заказы поставщикам 
INSERT INTO SupplierOrders (SupplierId, EmployeeId)
VALUES (1, 1), (2, 1), (1, 1), (2, 1);

INSERT INTO SupplierOrderItems(SupplierOrderId, PartId, Quantity, UnitCost)
VALUES 
(1, 1, 5, 1000), (1, 2, 5, 1000), 
(2, 1, 5, 1000), (2, 2, 5, 1000), 
(1, 1, 5, 1000), (1, 2, 5, 1000), 
(2, 1, 5, 1000), (2, 2, 5, 1000),
(3, 3, 5, 1000), (3, 4, 5, 1000),
(4, 4, 5, 1000), (4, 4, 5, 1000);

UPDATE SupplierOrders
SET Status = 'completed'
WHERE SupplierOrderId IN (1, 3, 4);
UPDATE SupplierOrders
SET Status = 'cancelled'
WHERE SupplierOrderId = 2;

-- Заказы покупателей
INSERT INTO Orders (ClientId, EmployeeId, Status)
VALUES (1, 1, 'pending'), (1, 1, 'pending'), (2, 2, 'pending'), (3, 3, 'pending');

INSERT INTO OrderItems (OrderId, ItemType, PartId, CarId, Quantity, UnitPrice)
VALUES 
	(1, 'car', NULL, 1, 1, 1000000), (1, 'part', 1, NULL, 10, 1000),
	(2, 'car', NULL, 2, 1, 1000000), (2, 'part', 2, NULL, 10, 1000),
	(3, 'part', 3, NULL, 1, 1000000), (3, 'part', 3, NULL, 2, 1000),
	(4, 'part', 4, NULL, 1, 1000000), (4, 'part', 4, NULL, 2, 1000);

UPDATE Orders
SET Status = 'completed'
WHERE OrderId IN (1, 3, 4);

SELECT * FROM Parts;
SELECT * FROM SupplierOrders;
SELECT * FROM SupplierOrderItems;
UPDATE Orders
SET Status = 'cancelled'
WHERE OrderId = 2;

SELECT * FROM Invoices;
SELECT * FROM Orders;
SELECT * FROM OrderItems;
SELECT * FROM SupplierInvoices;
SELECT * FROM SupplierOrders;
SELECT * FROM SupplierOrderItems;
SELECT * FROM InventoryMovements;
SELECT * FROM Parts;
GO

-- ================ Тест создания счёт фактуры через процедуру =======================================
-- Фактура для заказов клиентов (с попыткой добавить 2 фактуры на 1 заказ. В итоге для 4 заказа не добавится ни одна фактура)
SELECT * FROM Orders;
SELECT * FROM Invoices;

DELETE FROM Invoices
WHERE OrderId IN (1, 2, 3, 4);

DECLARE @InvoiceData InvoiceDataCommonType;
INSERT INTO @InvoiceData (ReferenceId, IssueDate, DueDate)
VALUES 
    (1, '2024-01-15', '2024-02-15'),
    (2, NULL, NULL),
    (3, NULL, NULL),
    (4, NULL, NULL),
    (4, NULL, NULL);
-- Сразу несколько фактур
EXEC usp_CreateInvoices @Invoices = @InvoiceData;
-- Только 1 фактура
EXEC usp_CreateInvoice @InvoiceId = 4;
SELECT * FROM Orders;
SELECT * FROM Invoices;

-- Попытка добавить фактуру на заказ клиента, у которого уже есть фактура
EXEC usp_CreateInvoice @InvoiceId = 4;
SELECT * FROM Invoices;
GO

-- Фактура для заказов поставщиков (с попыткой добавить 2 фактуры на 1 заказ. В итоге для 4 заказа не добавится ни одна фактура)
SELECT * FROM SupplierOrders;
SELECT * FROM SupplierInvoices;

DELETE FROM SupplierInvoices
WHERE SupplierOrderId IN (1, 2, 3, 4);

DECLARE @SupplierInvoiceData InvoiceDataCommonType;
INSERT INTO @SupplierInvoiceData (ReferenceId, IssueDate, DueDate)
VALUES 
    (1, '2024-01-15', '2024-02-15'),
    (2, NULL, NULL),
    (3, '2024-01-16', NULL),
    (4, NULL, NULL),
    (4, NULL, NULL);
EXEC usp_CreateSupplierInvoices @SupplierInvoices = @SupplierInvoiceData;
SELECT * FROM SupplierOrders;
SELECT * FROM SupplierInvoices;
-- Попытка добавить фактуру на заказ клиента, у которого уже есть фактура
INSERT INTO @SupplierInvoiceData (ReferenceId, IssueDate, DueDate)
VALUES (1, NULL, NULL)
GO

-- ============================= Тест создания заказа клиенту через процедуру ============================
-- Добавление, но не всех товаров из-за количества
SELECT * FROM Orders
DECLARE @OrderItems AS OrderItemsType;
INSERT INTO @OrderItems (ItemType, ItemId, Quantity)
VALUES
('car', 4, 1),
('part', 1, 3),
('part', 1, 2);
DECLARE @OrderId INT;
EXEC usp_CreateCustomerOrder @ClientId = 1, @EmployeeId = 9999, @Items = @OrderItems, @OrderId = @OrderId OUTPUT;
SELECT * FROM Orders
SELECT * FROM OrderItems;
-- Несуществующий клиент
EXEC usp_CreateCustomerOrder @ClientId = 9999, @EmployeeId = NULL, @Items = @OrderItems, @OrderId = @OrderId OUTPUT;
-- Пустые данные
DECLARE @OrderItems2 AS OrderItemsType;
EXEC usp_CreateCustomerOrder @ClientId = 1, @EmployeeId = 1, @Items = @OrderItems2, @OrderId = @OrderId OUTPUT;

-- ============================= Тест создания заказа поставщику через процедуру ============================
-- Добавление, но не всех товаров из-за количества
SELECT * FROM SupplierOrders
SELECT * FROM SupplierOrderItems;
DECLARE @PartsToOrder PartsToOrderType;
INSERT INTO @PartsToOrder (PartId, Quantity, UnitPrice)
VALUES
(1, 20, 900),
(2, 25, 1500),
(3, 30, 1000);
EXEC usp_CreateSupplierOrders @PartsToOrder = @PartsToOrder;
SELECT * FROM SupplierOrders
SELECT * FROM SupplierOrderItems;
-- Пустые данные
DECLARE @PartsToOrder2 PartsToOrderType;
EXEC usp_CreateSupplierOrders @PartsToOrder = @PartsToOrder2
-- Вставка одиночного заказа
EXEC usp_CreateSupplierOrder @PartId = 1, @EmployeeId = 1, @Quantity = 10, @UnitPrice = 800;
SELECT * FROM SupplierOrders
SELECT * FROM SupplierOrderItems;

GO
-- ========================= Тест удаления сотрудника =================================
-- Создание одиночного заказа поставщику на сотрудника
EXEC usp_CreateSupplierOrder @PartId = 1, @EmployeeId = 1, @Quantity = 10, @UnitPrice = 800;
UPDATE SupplierOrders
SET Status = 'completed'
WHERE SupplierOrderId = 1;
-- Создание одиночного заказа клиента на сотрудника
DECLARE @OrderItems OrderItemsType;
INSERT INTO @OrderItems(ItemType, ItemId, Quantity)
VALUES ('part', 1, 5)
DECLARE @OrderId INT;
EXEC usp_CreateCustomerOrder @ClientId = 1, @EmployeeId = 1, @Items = @OrderItems, @OrderId = @OrderId OUTPUT;
-- Создание корректировки движений на сотрудника
INSERT InventoryMovements (ItemType, PartId, MovementType, Quantity, EmployeeId)
VALUES ('part', 1, 'adjustment', 10, 1)
SELECT * FROM Orders;
SELECT * FROM SupplierOrders;
SELECT * FROM InventoryMovements;
DELETE FROM Employees WHERE EmployeeId = 1;
SELECT * FROM Orders;
SELECT * FROM SupplierOrders;
SELECT * FROM InventoryMovements;

GO
--=========================== Тест удаление движений товаров =======================
-- Создание одиночного заказа поставщику
EXEC usp_CreateSupplierOrder @PartId = 1, @Quantity = 10, @UnitPrice = 800;
EXEC usp_CreateSupplierOrder @PartId = 2, @Quantity = 10, @UnitPrice = 800;
EXEC usp_CreateSupplierOrder @PartId = 3, @Quantity = 10, @UnitPrice = 800;
EXEC usp_CreateSupplierOrder @PartId = 3, @Quantity = 10, @UnitPrice = 800;
DECLARE @PartsToOrder PartsToOrderType;
INSERT INTO @PartsToOrder (EmployeeId, PartId, Quantity, UnitPrice)
VALUES
(6, 4, 11, 1500),
(7, 6, 12, 1500),
(7, 6, 12, 1500)

EXEC usp_CreateSupplierOrders @PartsToOrder;
UPDATE SupplierOrders
SET Status = 'completed'
WHERE SupplierOrderId IN (1, 2, 4, 6, 7, 8, 9);
-- Создание одиночного заказа клиента
DECLARE @OrderItems OrderItemsType;
INSERT INTO @OrderItems(ItemType, ItemId, Quantity)
VALUES ('part', 3, 1), ('part', 6, 1)
DECLARE @OrderId INT;
EXEC usp_CreateCustomerOrder @ClientId = 2, @Items = @OrderItems, @OrderId = @OrderId OUTPUT;
EXEC usp_CreateCustomerOrder @ClientId = 2, @Items = @OrderItems, @OrderId = @OrderId OUTPUT;
EXEC usp_CreateCustomerOrder @ClientId = 2, @Items = @OrderItems, @OrderId = @OrderId OUTPUT;
EXEC usp_CreateCustomerOrder @ClientId = 3, @Items = @OrderItems, @OrderId = @OrderId OUTPUT;
EXEC usp_CreateCustomerOrder @ClientId = 4, @Items = @OrderItems, @OrderId = @OrderId OUTPUT;
EXEC usp_CreateCustomerOrder @ClientId = 5, @Items = @OrderItems, @OrderId = @OrderId OUTPUT;
UPDATE Orders
SET Status = 'completed'
WHERE OrderId = 1;
UPDATE Orders
SET Status = 'cancelled'
WHERE OrderId = 2;
-- Создание корректировки движений
INSERT InventoryMovements (ItemType, PartId, MovementType, Quantity, EmployeeId)
VALUES ('part', 3, 'adjustment', -3, 2)

-- Удаление корректировки товара, удаление позиции из заказа, удаление заказа
SELECT * FROM Parts;
SELECT * FROM InventoryMovements;
DELETE FROM InventoryMovements WHERE MovementId = 13;
SELECT * FROM Parts;
SELECT * FROM InventoryMovements;
SELECT * FROM OrderItems;
DELETE FROM OrderItems WHERE OrderItemId IN (1, 3, 5);
SELECT * FROM Parts;
SELECT * FROM InventoryMovements;
SELECT * FROM OrderItems;
DELETE FROM Orders WHERE OrderId IN (1, 2, 3);
SELECT * FROM Parts;
SELECT * FROM InventoryMovements;
SELECT * FROM OrderItems;


-- Удаление удаление позиции из заказа, удаление заказа у поставщиков
SELECT * FROM Parts;
SELECT * FROM InventoryMovements;
SELECT * FROM SupplierOrderItems;
SELECT * FROM SupplierOrders;
DELETE FROM SupplierOrderItems WHERE SupplierOrderItemId = 1;
SELECT * FROM Parts;
SELECT * FROM InventoryMovements;
SELECT * FROM SupplierOrderItems;
SELECT * FROM SupplierOrders;
DELETE FROM SupplierOrders WHERE SupplierOrderId = 2;
DELETE FROM SupplierOrders WHERE SupplierOrderId = 3;
SELECT * FROM Parts;
SELECT * FROM InventoryMovements;
SELECT * FROM SupplierOrderItems;
SELECT * FROM SupplierOrders;

-- Удаление клиента
SELECT * FROM OrderItems;
SELECT * FROM Orders;
DELETE FROM Clients WHERE ClientId = 1;
SELECT * FROM OrderItems;
SELECT * FROM Orders;

-- Удаление поставщика
SELECT * FROM InventoryMovements;
SELECT * FROM Parts;
SELECT * FROM Suppliers;
DELETE FROM Suppliers WHERE SupplierId = 1;
SELECT * FROM InventoryMovements;
SELECT * FROM Parts;
SELECT * FROM Suppliers;

-- Удаление товара
SELECT * FROM InventoryMovements;
SELECT * FROM Parts;
DELETE FROM Parts WHERE PartId = 2;
SELECT * FROM InventoryMovements;
SELECT * FROM Parts;


SELECT * FROM InventoryMovements;
SELECT * FROM Orders;
SELECT * FROM OrderItems;
SELECT * FROM SupplierOrders;
SELECT * FROM SupplierOrderItems;
SELECT * FROM Invoices;
SELECT * FROM SupplierInvoices;
SELECT * FROM Parts;



-- Тест расчёта скидки
SELECT * FROM InventoryMovements
GO
DECLARE @OrderItems OrderItemsType;
DECLARE @NewOrderId INT;
DECLARE @ClientId INT = 3
INSERT INTO @OrderItems (ItemType, ItemId, Quantity)
VALUES('car', 1, 1);

SELECT * FROM Orders WHERE ClientId = @ClientId;
SELECT * FROM OrderItems WHERE OrderId IN (SELECT OrderId FROM Orders WHERE ClientId = @ClientId);
SELECT TOP 5 * FROM CarInventory;
EXEC usp_CreateCustomerOrder @ClientId = @ClientId, @Items = @OrderItems, @OrderId = @NewOrderId;
UPDATE Orders
SET Status = 'completed'
WHERE ClientId = @ClientId
UPDATE @OrderItems
SET ItemId = 2;
EXEC usp_CreateCustomerOrder @ClientId = @ClientId, @Items = @OrderItems, @OrderId = @NewOrderId;
UPDATE Orders
SET Status = 'completed'
WHERE ClientId = @ClientId
UPDATE @OrderItems
SET ItemId = 3;
EXEC usp_CreateCustomerOrder @ClientId = @ClientId, @Items = @OrderItems, @OrderId = @NewOrderId;
UPDATE Orders
SET Status = 'completed'
WHERE ClientId = @ClientId
SELECT * FROM Orders WHERE ClientId = @ClientId;
SELECT * FROM OrderItems WHERE OrderId IN (SELECT OrderId FROM Orders WHERE ClientId = @ClientId);
SELECT TOP 5 * FROM CarInventory;
DELETE FROM Orders
WHERE ClientId = @ClientId
SELECT * FROM Orders WHERE ClientId = @ClientId;
SELECT * FROM OrderItems WHERE OrderId IN (SELECT OrderId FROM Orders WHERE ClientId = @ClientId);
SELECT TOP 5 * FROM CarInventory;
UPDATE CarInventory
SET IsAvailable = 1
WHERE CarId IN (1, 2, 3);
GO

-- Тест поиска запчастей на машину
-- Поиск будет только по VIN
EXEC usp_FindPartsForCar
@VIN = 'WBA5R1C57J1234571',
@Brand = 'Toyota',
@Model = 'RAV4',
@Generation = 'XA50',
@Trim = 'Comfort';
-- Поиск по поколению
EXEC usp_FindPartsForCar
@Brand = 'Toyota',
@Model = 'RAV4',
@Generation = 'XA50';

GO



-- Тест функции оценки
DECLARE @TestCarId INT = 17; -- 1 для нового, 17 для бу
SELECT dbo.FN_CalculateCarCost(@TestCarId) AS TradeInValue;
SELECT *
FROM CarTrims
WHERE TrimId = (SELECT TrimId FROM CarInventory WHERE CarId = @TestCarId)
SELECT * FROM CarInventory WHERE CarId = @TestCarId


-- Тест процедуры добавления авто
DECLARE @NewCarId INT, @Value DECIMAL(10,2);
EXEC usp_AddCarForTradeIn
	@TrimId = 3,
	@Color = 'Черный',
	@Vin = 'ABC123456789DEE03',
	@ManufacturedYear = 2017,
	@Mileage = 65000,
	@CarId = @NewCarId OUTPUT,
	@TradeInValue = @Value OUTPUT;

SELECT @NewCarId AS NewCarId, @Value AS TradeInValue;
SELECT * FROM CarInventory
SELECT * FROM InventoryMovements;
DELETE FROM CarInventory WHERE CarId = @NewCarId;
SELECT * FROM InventoryMovements;

-- Тест процедуры трейд-ина
GO
DECLARE @NewCarId INT = 9, @OldCarId INT, @OrderId INT;

SELECT * FROM InventoryMovements;
SELECT * FROM Orders --WHERE OrderId = @OrderId;
SELECT * FROM OrderItems --WHERE OrderId = @OrderId;
SELECT * FROM CarInventory WHERE CarId IN (@NewCarId);

EXEC usp_TradeInCar
	@NewCarId = @NewCarId, -- ID нового авто в инвентаре
	@OldCarTrimId = 3,
	@OldCarColor = 'Черный',
	@OldCarVin = 'TRADEIN1234567892',
	@OldCarManufacturedYear = 2017,
	@OldCarMileage = 65000,
	@ClientId = 5,
	@EmployeeId = 2,
	@TradeInCarId = @OldCarId OUTPUT,
	@OrderId = @OrderId OUTPUT;

SELECT * FROM InventoryMovements;
SELECT * FROM Orders --WHERE OrderId = @OrderId;
SELECT * FROM OrderItems --WHERE OrderId = @OrderId;
SELECT * FROM CarInventory WHERE CarId IN (@OldCarId, @NewCarId);

DELETE FROM CarInventory
WHERE CarId = @OldCarId;
DELETE FROM Orders
WHERE OrderId = @OrderId;

UPDATE CarInventory
SET IsAvailable = 1
WHERE CarId = @NewCarId;