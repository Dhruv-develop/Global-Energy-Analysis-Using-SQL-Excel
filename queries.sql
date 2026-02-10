USE sql_excel_project;

SELECT * FROM energy;



-- Problem 1: Data Understanding & Exploration
-- 1.	Count total records in the dataset
SELECT COUNT(*) AS No_of_records FROM energy; 

-- 2.	Identify:
-- o	Number of unique regions
SELECT DISTINCT(region) AS Unique_Region FROM energy;

-- o	Number of unique scenarios
SELECT DISTINCT(scenario) AS Unique_Region FROM energy;

-- o	Year range available in the dataset
SELECT MIN(year) AS Start_Year,MAX(year) AS Ending_Year FROM energy;



-- Problem 2: Regional Energy Trends
-- Find total energy supply 
-- •	Grouped by REGION
-- •	For each YEAR
-- •	Only for Historical scenario

SELECT region,ROUND(SUM(value),2) AS Total_energy_supplied 
FROM energy
GROUP BY region; 

SELECT year,ROUND(SUM(value),2) AS Total_energy_supplied 
FROM energy
GROUP BY year; 

SELECT Scenario,ROUND(SUM(value),2) AS Total_energy_supplied 
FROM energy
WHERE Scenario = "Historical"
GROUP BY Scenario;

SELECT year,region,ROUND(SUM(value),2) AS Total_energy_supplied 
FROM energy
WHERE scenario = "Historical"
GROUP BY region,year; 



-- Problem 3: Scenario Comparison
-- For each REGION, calculate:
-- •	Total energy value for each SCENARIO
-- •	Sort regions by highest total energy

SELECT region,scenario,ROUND(SUM(value),2) AS Total_energy_supplied 
FROM energy 
GROUP BY region,scenario
ORDER BY Total_energy_supplied DESC;



-- Problem 4: Create a Business-Ready View
-- Create a derived column:
-- Energy_Level
-- - 'Low'    → VALUE < 300
-- - 'Medium' → VALUE between 300 and 600
-- - 'High'   → VALUE > 600
-- This column will be used later for dashboard segmentation.

ALTER TABLE energy ADD COLUMN energy_level VARCHAR(20);

SET sql_safe_updates = false;

UPDATE energy 
SET energy_level = 
CASE
WHEN value < 300 THEN "Low"
WHEN value BETWEEN 300 AND 600 THEN "Medium"
ELSE "High"
END;



-- Problem 5: Year-on-Year Growth (Advanced Basic)
-- For World region only:
-- •	Calculate YoY energy growth for each scenario
-- •	Output columns:
-- o	YEAR
-- o	SCENARIO
-- o	VALUE
-- o	Previous_Year_Value
-- o	Growth_Value

SELECT year,scenario,value, 
LAG(value) OVER(PARTITION BY scenario ORDER BY year) AS Previous_Year_Value,
ROUND(value - LAG(value) OVER(PARTITION BY scenario ORDER BY year)) AS Growth_Value
FROM energy
WHERE region = "World";

SELECT year,scenario,SUM(value) AS Total_value, 
LAG(SUM(value)) OVER(PARTITION BY scenario ORDER BY year) AS Previous_Year_Value,
ROUND(SUM(value) - LAG(SUM(value)) OVER(PARTITION BY scenario ORDER BY year)) AS Growth_Value
FROM energy
WHERE region = "World"
GROUP BY year,scenario;



-- Problem 6: Data Cleaning for Excel
-- Prepare a final export table with:
-- •	Remove columns: PUBLICATION, UNIT
-- •	Rename columns:
-- o	VALUE → Energy_Value
-- •	Add column:
-- o	Decade (2010s, 2020s, 2030s…)
-- Make data Excel-friendly and business-readable


ALTER TABLE energy DROP COLUMN publication;
ALTER TABLE energy DROP COLUMN unit;

ALTER TABLE energy RENAME COLUMN value TO energy_value;

ALTER TABLE energy ADD COLUMN decade VARCHAR(20);

SET sql_safe_updates = 0;

UPDATE energy
SET decade = CONCAT(FLOOR(year / 10) * 10, 's');




-- Problem 7: Create SQL Views for Excel Import
-- Create two SQL views:
-- View 1: regional_energy_summary
-- •	REGION
-- •	YEAR
-- •	SCENARIO
-- •	Total_Energy

CREATE VIEW regional_energy_summary AS
SELECT
    REGION,
    YEAR,
    SCENARIO,
    SUM(energy_value) AS Total_Energy
FROM energy
GROUP BY REGION, YEAR, SCENARIO;

DROP VIEW regional_energy_summary;

SELECT * FROM regional_energy_summary;

-- View 2: scenario_comparison
-- •	REGION
-- •	SCENARIO
-- •	Avg_Energy_Value

CREATE VIEW scenario_comparison AS
SELECT
    REGION,
    SCENARIO,
    ROUND(AVG(energy_value), 2) AS Avg_Energy_Value
FROM energy
GROUP BY REGION, SCENARIO;

SELECT * FROM scenario_comparison;