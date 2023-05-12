-- PRELIMINARY RESEARCH


-- Top 10 districts with highest number of domestic visitors overall
SELECT TOP 10 district, SUM(visitors) AS total_domestic_visitors
FROM [TelanganaGovtTourism ].[dbo].[domestic_visitors]
GROUP BY district
ORDER BY total_domestic_visitors DESC;


/* There is a discrepancy in the spelling of the district 'Narayanapet'/'Narayanpet' between the domestic_visitors and foreign_visitors tables. 
The domestic_visitors table is updated so that both tables will have the same spelling */
 
UPDATE domestic_visitors
SET district = 'Narayanpet'
WHERE district = 'Narayanapet';


-- Create a temp table with the combined visitors numbers for each district per year per month
DROP TABLE IF EXISTS #combined_visitors;
SELECT district, year, month, SUM(visitors) AS total_visitors 
INTO #combined_visitors
FROM (SELECT * FROM domestic_visitors 
	  UNION	
	  SELECT * FROM foreign_visitors)t
GROUP BY district, year, month;


-- Top 3 districts based on CAGR of visitors between 2016-2019
WITH visitors16 AS(
	SELECT district,SUM(total_visitors) AS total_visitors_yearly 
	FROM #combined_visitors 
	WHERE year = 2016 
	GROUP BY district, year 
),
	visitors19 AS(
	SELECT district,SUM(total_visitors) AS total_visitors_yearly  
	FROM #combined_visitors 
	WHERE year = 2019 
	GROUP BY district, year
)
 SELECT TOP 3 v16.district,CAST(ROUND(((POWER((v19.total_visitors_yearly/(v16.total_visitors_yearly*1.0)),(1/4.0)))-1),2) AS DECIMAL(10,2)) AS CAGR_2016_2019
 FROM visitors16 v16 INNER JOIN visitors19 v19 ON v16.district = v19.district 
 WHERE v19.total_visitors_yearly !=0  AND v16.total_visitors_yearly !=0
 ORDER BY CAGR_2016_2019 DESC;


 -- Bottom 3 districts based on CAGR of visitors between 2016-2019
WITH visitors16 AS(
	SELECT district,SUM(total_visitors) AS total_visitors_yearly 
	FROM #combined_visitors 
	WHERE year = 2016
	GROUP BY district, year
),
	visitors19 AS(
	SELECT district,SUM(total_visitors) AS total_visitors_yearly 
	FROM #combined_visitors 
	WHERE year = 2019 
	GROUP BY district, year
)
 SELECT TOP 3 v16.district,CAST(((POWER((v19.total_visitors_yearly/(v16.total_visitors_yearly*1.0)),(1/4.0)))-1) AS DECIMAL(10,2)) AS CAGR_2016_2019
 FROM visitors16 v16 INNER JOIN visitors19 v19 ON v16.district = v19.district
  WHERE v19.total_visitors_yearly !=0  AND v16.total_visitors_yearly !=0
 ORDER BY CAGR_2016_2019;


 -- Peak and low season months for the district of Hyderabad based on data from 2016 to 2019
 SELECT month,AVG(total_visitors) AS avg_visitors_per_month 
 FROM #combined_visitors
 WHERE district = 'Hyderabad'
 GROUP BY month
 ORDER BY avg_visitors_per_month DESC;


 --Top 3 districts with highest domestic to foreign tourist ratio
 WITH d AS(
 SELECT district, SUM(visitors) AS domestic_visitors 
 FROM domestic_visitors
 GROUP BY district
 ),
 f AS(
  SELECT district, SUM(visitors) AS foreign_visitors 
 FROM foreign_visitors
 GROUP BY district
 )
 SELECT TOP 3 d.district, d.domestic_visitors/f.foreign_visitors AS 'd/f'
 FROM d INNER JOIN f ON d.district = f.district 
 WHERE d.domestic_visitors !=0 AND f.foreign_visitors != 0
 ORDER BY 'd/f' DESC;


  --Bottom 3 districts with domestic to foreign tourist ratio
 WITH d AS(
 SELECT district, SUM(visitors) AS domestic_visitors 
 FROM domestic_visitors
 GROUP BY district
 ),
 f AS(
  SELECT district, SUM(visitors) AS foreign_visitors 
 FROM foreign_visitors
 GROUP BY district
 )
 SELECT TOP 3 d.district, d.domestic_visitors/f.foreign_visitors AS 'd/f'
 FROM d INNER JOIN f ON d.district = f.district 
 WHERE d.domestic_visitors !=0 AND f.foreign_visitors != 0
 ORDER BY 'd/f';



 -- SECONDARY RESEARCH
 
 -- Top 5 districts based on population to tourist footfall ratio in 2019

/* Population data is collected from the Telangana government website and imported as a CSV file 
   after fixing the district spellings to ensure compatibility with the existing datasets */

WITH t1 AS (
	SELECT district, SUM(total_visitors) AS visitors
	 FROM #combined_visitors
	 WHERE year = 2019
	 GROUP BY district, year
 )
 SELECT TOP 5 t1.district, CAST(ROUND(t1.visitors/(p.population*1.0), 3) AS DECIMAL(10, 2)) AS 'tourist_footfall/population'
 FROM t1 LEFT JOIN population p ON t1.district = p.district
 WHERE (t1.visitors IS NOT NULL) AND t1.visitors!=0
 ORDER BY 'tourist_footfall/population' DESC;


-- Bottom 5 districts based on population to tourist footfall ratio in 2019

WITH t1 AS (
	SELECT district, SUM(total_visitors) AS visitors
	 FROM #combined_visitors
	 WHERE year = 2019
	 GROUP BY district, year
 )
 SELECT TOP 5 t1.district,t1.visitors,p.population, CAST(ROUND(t1.visitors/(p.population*1.0), 3) AS DECIMAL(10, 2)) AS 'tourist_footfall/population'
 FROM t1 LEFT JOIN population p ON t1.district = p.district
  WHERE t1.visitors IS NOT NULL AND t1.visitors!=0
 ORDER BY 'tourist_footfall/population' ;
  

 -- Projected number of domestic and foreign tourists in Hyderabad in 2025
 
 -- Step 1: Calculate growth rate for tourists based on data from 2016 to 2019
 -- Step 2: Use the growth rate to calculate the projected tourist number for 2025


 -- Projected count of domestic tourists for Hyderabad in 2025
 WITH t1 AS(
 	SELECT district,SUM(visitors) AS domestic_visitors_2016 
	FROM domestic_visitors 
	WHERE year = 2016 AND district = 'Hyderabad'
	GROUP BY district
	),
	t2 AS(
 	SELECT district,SUM(visitors) AS domestic_visitors_2019 
	FROM domestic_visitors 
	WHERE year = 2019 AND district = 'Hyderabad'
	GROUP BY district
	)
	SELECT CAST(t2.domestic_visitors_2019*(POWER((1+CAST(ROUND(POWER((t2.domestic_visitors_2019/(t1.domestic_visitors_2016*1.0)),(1/4.0))-1, 2) AS DECIMAL(15,2))),6)) AS INT)
	FROM t1 LEFT JOIN t2 ON t1.district = t2.district;


 -- Projected count of foreign tourists for Hyderabad in 2025
 WITH t1 AS(
 	SELECT district,SUM(visitors) AS foreign_visitors_2016 
	FROM foreign_visitors 
	WHERE year = 2016 AND district = 'Hyderabad'
	GROUP BY district
	),
	t2 AS(
 	SELECT district,SUM(visitors) AS foreign_visitors_2019 
	FROM foreign_visitors 
	WHERE year = 2019 AND district = 'Hyderabad'
	GROUP BY district
	)
	SELECT CAST(t2.foreign_visitors_2019*(POWER((1+CAST(ROUND(POWER((t2.foreign_visitors_2019/(t1.foreign_visitors_2016*1.0)),(1/4.0))-1, 2) AS DECIMAL(15,2))),6)) AS INT)
	FROM t1 LEFT JOIN t2 ON t1.district = t2.district;


-- Projected Revenue for Hyderabad in 2025 if average spend per domestic tourist is Rs 1200 and per foreign tourist is Rs 5600
 WITH t1 AS(
 	SELECT district,SUM(visitors) AS domestic_visitors_2016 
	FROM domestic_visitors 
	WHERE year = 2016 AND district = 'Hyderabad'
	GROUP BY district
	),
	t2 AS(
 	SELECT district,SUM(visitors) AS domestic_visitors_2019 
	FROM domestic_visitors 
	WHERE year = 2019 AND district = 'Hyderabad'
	GROUP BY district
	),
	t3 AS(
 	SELECT district,SUM(visitors) AS foreign_visitors_2016 
	FROM foreign_visitors 
	WHERE year = 2016 AND district = 'Hyderabad'
	GROUP BY district
	),
	t4 AS(
 	SELECT district,SUM(visitors) AS foreign_visitors_2019 
	FROM foreign_visitors 
	WHERE year = 2019 AND district = 'Hyderabad'
	GROUP BY district
	)
SELECT 'Domestic' AS tourist_type, 1200 *(CAST(t2.domestic_visitors_2019*(POWER((1+CAST(ROUND(POWER((t2.domestic_visitors_2019/(t1.domestic_visitors_2016*1.0)),(1/4.0))-1, 2) AS DECIMAL(15,2))),6)) AS bigint)) AS Revenue
	FROM t1 LEFT JOIN t2 ON t1.district = t2.district
UNION 
SELECT 'Foreign' AS tourist_type, 5600*(CAST(t4.foreign_visitors_2019*(POWER((1+CAST(ROUND(POWER((t4.foreign_visitors_2019/(t3.foreign_visitors_2016*1.0)),(1/4.0))-1, 2) AS DECIMAL(15,2))),6)) AS bigint)) AS Revenue
	FROM t3 LEFT JOIN t4 ON t3.district = t4.district;



