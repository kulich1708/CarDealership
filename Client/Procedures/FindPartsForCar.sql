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