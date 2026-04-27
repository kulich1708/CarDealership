-- Отображение всех БУ машин + модификаций новых машин
DROP VIEW IF EXISTS VW_AllAvailableCars;
GO
CREATE VIEW VW_AllAvailableCars AS
SELECT 
BrandName,
ModelName,
GenerationName,
TrimName,
'BrandNew' AS Status,
BodyType,
FuelType,
DriveType,
Transmission, 
EnginePower,
Colors,
MinYear,
MaxYear,
Mileage,
MinPrice,
MaxPrice,
CarCount
FROM VW_AvailableBrandNewCars 
UNION 
SELECT 
BrandName,
ModelName,
GenerationName,
TrimName,
'Used' AS Status,
BodyType,
FuelType,
DriveType,
Transmission, 
EnginePower,
Color AS Colors,
ManufacturedYear AS MinYear,
ManufacturedYear AS MaxYear,
Mileage,
Price AS MinPrice,
Price AS MaxPrice,
1 AS CarCount
FROM VW_AvailableUsedCars;
GO