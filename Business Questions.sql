-- 
-- 1. List all trims with MPG above the fleet average MPG
WITH FleetAverage AS (
    SELECT CAST(AVG((CityMPG + HighwayMPG) / 2.0) AS DECIMAL(3, 1)) AS FleetAverageMPG
    FROM TrimSpec
	)
SELECT
	v.Year,
	ma.MakeName,
	mo.ModelName,
	t.TrimName,
	CAST((ts.CityMPG + ts.HighwayMPG) / 2.0 AS float) AS CombinedMPG,
	fa.FleetAverageMPG
FROM Make ma
INNER JOIN Model mo ON ma.makeID = mo.ModelID
INNER JOIN Trim t ON mo.ModelID = t.ModelID
INNER JOIN TrimSpec ts ON t.TrimID = ts.TrimID
INNER JOIN Vehicle v ON t.TrimID = v.TrimID
INNER JOIN Engine e ON v.EngineID = e.EngineID
CROSS JOIN FleetAverage fa
WHERE (ts.CityMPG + ts.HighwayMPG) / 2 > fa.FleetAverageMPG
;

-- 2. Which trim of each model offers the best Horsepower-to-Curb Weight ratio?
WITH PowerToWeight_CTE AS (
SELECT
	v.Year,
	ma.MakeName,
	mo.ModelName,
	t.TrimName,
	e.Horsepower,
	ts.CurbWeightLb,
	CAST((e.horsepower * 1.0 / ts.CurbWeightLb) AS decimal(6,5)) AS PowerToWeight_Ratio,
	ROW_NUMBER() OVER (
		PARTITION BY mo.ModelName 
		ORDER BY CAST((e.horsepower * 1.0 / ts.CurbWeightLb) AS decimal(6,5)) DESC
	) AS RatioRank
FROM Make ma
INNER JOIN Model mo ON ma.MakeID = mo.MakeID
INNER JOIN Trim t ON mo.ModelID = t.ModelID
INNER JOIN Vehicle v ON t.TrimID = v.TrimID
INNER JOIN Engine e ON v.EngineID = e.EngineID
INNER JOIN TrimSpec ts ON t.TrimID = ts.TrimID
	)
SELECT *
FROM PowerToWeight_CTE
WHERE RatioRank = 1
;


-- 3. Categorize trims by power-to-weight ratio.
SELECT
	ma.MakeName,
	mo.ModelName,
	t.TrimName,
	e.Horsepower,
	ts.CurbWeightLb,
	ROUND(CAST(e.horsepower * 1.0 / ts.CurbWeightLb AS float), 4) AS PowerToWeight_Ratio,
	CASE
		WHEN CAST(e.horsepower * 1.0 / ts.CurbWeightLb AS float) >= .08 THEN 'High Performance'
		WHEN CAST(e.horsepower * 1.0 / ts.CurbWeightLb AS float) >= .06 THEN 'Moderate Performance'
		ELSE 'Low Performance'
	END AS PerformanceCategory
FROM Make ma
INNER JOIN Model mo ON ma.MakeID = mo.MakeID
INNER JOIN Trim t ON mo.ModelID = t.ModelID
INNER JOIN Vehicle v ON t.TrimID = v.TrimID
INNER JOIN Engine e ON v.EngineID = e.EngineID
INNER JOIN TrimSpec ts ON t.TrimID = ts.TrimID
WHERE e.Horsepower IS NOT NULL AND ts.CurbWeightLb IS NOT NULL
;

-- 4. We'd like to advertise our fastest and oldest cars, one from each model to show off our variety.
WITH cte_PowerToWeight AS (
SELECT
	v.Year,
	m.MakeName,
	mo.ModelName,
	t.TrimName,
	e.EngineCode,
	e.Horsepower,
	ts.CurbWeightLb,
	CAST(e.Horsepower * 1.0 / ts.CurbWeightLb AS DECIMAL(6,5)) * 10 AS PowerToWeight,
	ROW_NUMBER() OVER (
		PARTITION BY mo.ModelName 
		ORDER BY e.Horsepower * 1.0 / ts.CurbWeightLb DESC, v.year
	) AS ByModel
FROM Make m
INNER JOIN Model mo ON m.MakeID = mo.MakeID
INNER JOIN Trim t ON mo.ModelID = t.ModelID
INNER JOIN TrimSpec ts ON t.TrimID = ts.TrimID
INNER JOIN Vehicle v ON t.TrimID = v.TrimID
INNER JOIN Engine e ON v.EngineID = e.EngineID
)
SELECT *
FROM cte_PowerToWeight
WHERE ByModel = 1
ORDER BY PowerToWeight DESC, Year
;

-- 5. Are there any duplicate trim names with the same model/year but different specs?
SELECT
	v.Year,
	mo.ModelName,
	t.TrimName,
	COUNT(DISTINCT ts.TrimID)
FROM Make m
INNER JOIN Model mo ON m.MakeID = mo.MakeID
INNER JOIN Trim t ON mo.ModelID = t.ModelID
INNER JOIN TrimSpec ts ON t.TrimID = ts.TrimID
INNER JOIN Vehicle v ON t.TrimID = v.TrimID 
INNER JOIN Engine e ON v.EngineID = e.EngineID
GROUP BY v.Year, mo.ModelName, t.TrimName 
;

-- 6. Do any trims ever use multiple engines across different years?
SELECT
	m.MakeName,
	mo.ModelName,
	t.TrimName,
	COUNT(DISTINCT e.EngineCode) AS EngineCount,
	COUNT(DISTINCT v.Year) AS YearCount
FROM Make m
INNER JOIN Model mo ON m.MakeID = mo.MakeID
INNER JOIN Trim t ON mo.ModelID = t.ModelID
INNER JOIN Vehicle v ON t.TrimID = v.TrimID 
INNER JOIN Engine e ON v.EngineID = e.EngineID
GROUP BY m.MakeName, mo.ModelName, t.TrimName
HAVING COUNT(DISTINCT e.EngineCode) > 1
;

-- 7. Which trims had the highest combined MPG in their launch year?
WITH TrimLaunchYear AS (
	SELECT
		TrimID,
		MIN(Year) AS LaunchYear
	FROM Vehicle v
	GROUP BY TrimID
	), 
CombinedMPG_CTE AS (
	SELECT
		v.Year,
		m.MakeName,
		mo.ModelName,
		t.TrimName,
		CAST((ts.CityMPG + ts.HighwayMPG) / 2.0 AS DECIMAL(4,1)) AS CombinedMPG,
		RANK() OVER(
			PARTITION BY v.Year 
			ORDER BY CAST((ts.CityMPG + ts.HighwayMPG) / 2.0 AS DECIMAL(4,1))
		) AS CombinedMPG_Ranked
	FROM Make m
	JOIN Model mo ON m.MakeID = mo.MakeID
	JOIN Trim t ON mo.ModelID = t.ModelID
	JOIN TrimSpec ts ON t.TrimID = ts.TrimID
	JOIN Vehicle v ON t.TrimID = v.TrimID
	JOIN TrimLaunchYear tly ON v.TrimID = tly.TrimID AND v.Year = tly.LaunchYear
	)
SELECT *
FROM CombinedMPG_CTE
WHERE CombinedMPG_Ranked = 1
ORDER BY Year
;

-- 8. Which trims had a performance-to-MPG ratio higher than the average across all years?
WITH AverageRatio AS (
	SELECT
		CAST(AVG(CAST(e.Horsepower AS FLOAT) / ((ts.HighwayMPG + CityMPG) / 2.0)) AS decimal(4,2)) AS AllAverage
	FROM Vehicle v
	JOIN Engine e ON v.EngineID = e.EngineID
	JOIN Trim t ON v.TrimID = t.TrimID
	JOIN TrimSpec ts ON t.TrimID = ts.TrimID
		),
TrimRatio AS (
	SELECT
		v.Year,
		m.MakeName,
		mo.ModelName,
		t.TrimName,
		e.Horsepower,
		CAST((ts.HighwayMPG + ts.CityMPG) / 2 AS decimal(4,2)) AS CombinedMPG,
		CAST(CAST(e.horsepower AS float) / ((ts.HighwayMPG + ts.CityMPG) / 2.0) AS decimal(4,2)) AS PerformancePerMPG
	FROM Make m
	JOIN Model mo ON m.MakeID = mo.MakeID
	JOIN Trim t ON mo.ModelID = t.ModelID
	JOIN TrimSpec ts ON t.TrimID = ts.TrimID
	JOIN Vehicle v ON t.TrimID = v.TrimID
	JOIN Engine e ON v.EngineID = e.EngineID
		)
SELECT *
FROM TrimRatio tr
JOIN AverageRatio ar ON 1=1
WHERE tr.PerformancePerMPG > ar.AllAverage
ORDER BY tr.PerformancePerMPG DESC
;