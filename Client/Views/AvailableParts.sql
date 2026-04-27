DROP VIEW IF EXISTS VW_AvailableParts;
GO
CREATE VIEW VW_AvailableParts AS
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
WHERE p.Quantity > 0;
GO