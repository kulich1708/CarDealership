-- Отображение БУ машин
DROP VIEW IF EXISTS VW_AvailableUsedCars;
GO
CREATE VIEW VW_AvailableUsedCars AS
SELECT 
BrandName,
ModelName,
GenerationName,
TrimName,
BodyType,
FuelType,
DriveType,
Transmission, 
EnginePower,
Color,
ManufacturedYear,
Mileage,
Price,
dbo.FN_ConvertPrice (Price) AS PriceUSDT,
Vin
FROM Brands AS b
JOIN CarModels AS m ON m.BrandId = b.BrandId
JOIN ModelGenerations as g ON g.ModelId = m.ModelId
JOIN CarTrims AS t ON t.GenerationId = g.GenerationId
JOIN CarInventory AS i ON i.TrimId = t.TrimId
WHERE i.Mileage > 0 AND IsAvailable = 1;
GO

-- Отображение модификаций новых машин. 
DROP VIEW IF EXISTS VW_AvailableBrandNewCars;
GO
CREATE VIEW VW_AvailableBrandNewCars AS
WITH NewCarData AS (
	SELECT 
        i.TrimId,
        STRING_AGG(i.Color, ', ') AS Colors,
        MIN(i.ManufacturedYear) AS MinYear,
        MAX(i.ManufacturedYear) AS MaxYear,
        MIN(i.Price) AS MinPrice,
        MAX(i.Price) AS MaxPrice,
        COUNT(*) AS CarCount
    FROM CarInventory AS i
    WHERE i.Mileage = 0 
        AND i.IsAvailable = 1
    GROUP BY i.TrimId
)
SELECT 
BrandName,
ModelName,
GenerationName,
TrimName,
BodyType,
FuelType,
DriveType,
Transmission, 
EnginePower,
ncd.Colors AS Colors,
ncd.MinYear,
ncd.MaxYear,
0 AS Mileage,
ncd.MinPrice,
ncd.MaxPrice,
dbo.FN_ConvertPrice (ncd.MinPrice) AS MinPriceUSDT,
dbo.FN_ConvertPrice (ncd.MaxPrice) AS MaxPriceUSDT,
ncd.CarCount AS CarCount
FROM Brands AS b
JOIN CarModels AS m ON m.BrandId = b.BrandId
JOIN ModelGenerations as g ON g.ModelId = m.ModelId
JOIN CarTrims AS t ON t.GenerationId = g.GenerationId
JOIN NewCarData ncd ON t.TrimId = ncd.TrimId;
GO