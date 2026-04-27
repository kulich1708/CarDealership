-- Очистка данных
DELETE FROM CarInventory;
DELETE FROM CarTrims;
DELETE FROM ModelGenerations
DELETE FROM CarModels;
DELETE FROM Brands;
GO
-- Сброс IDENTITY (автоинкрементных счетчиков) для всех таблиц
DBCC CHECKIDENT ('CarInventory', RESEED, 0);
DBCC CHECKIDENT ('CarTrims', RESEED, 0);
DBCC CHECKIDENT ('CarModels', RESEED, 0);
DBCC CHECKIDENT ('Brands', RESEED, 0);
DBCC CHECKIDENT ('ModelGenerations', RESEED, 0);
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

