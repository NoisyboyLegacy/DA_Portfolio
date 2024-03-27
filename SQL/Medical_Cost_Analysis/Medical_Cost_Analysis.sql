create database Medical
use Medical	
select * from [dbo].[Medical_Data_Dataset]

CREATE TABLE #AGECAT (
    age INT,
    region NVARCHAR(MAX),
    charges FLOAT,
    AGECATEGORY NVARCHAR(MAX)
)

INSERT INTO #AGECAT (age, region, charges, AGECATEGORY)
SELECT 
    age, 
    region, 
    charges,
    CASE
        WHEN age <= 19 THEN 'TEEN'
        WHEN age BETWEEN 20 AND 39 THEN 'ADULT'
        WHEN age BETWEEN 40 AND 59 THEN 'MIDDLE AGE'
        WHEN age >= 60 THEN 'SENIOR'
    END
FROM [dbo].[Medical_Data_Dataset]

SELECT * FROM #AGECAT

-- AGE CATEGORY AVERAGES
SELECT
	DISTINCT AGECATEGORY,
	COUNT(*) OVER(PARTITION BY AGECATEGORY) AS AGECATE_COUNT,
	ROUND(AVG(charges) OVER (PARTITION BY AGECATEGORY),2) AS AVG_CHARGES_AGE
FROM #AGECAT
ORDER BY AVG_CHARGES_AGE DESC
-- CORRELATION BETWEEN AGE AND CHARGES
SELECT
	ROUND(CORR(age,charges),2) as Corr_age_charges
FROM [dbo].[Medical_Data_Dataset]
--Charges distribution
SELECT
	DISTINCT ROUND(charges,-4) as CHARGE_Bin,
	COUNT (*) AS count_bin
FROM [dbo].[Medical_Data_Dataset]
GROUP BY ROUND(charges,-4)
ORDER BY ROUND(charges,-4)
--Charges distribution male only
SELECT
	DISTINCT sex,
	ROUND(charges,-4) as CHARGE_Bin,
	COUNT (*) AS count_bin
FROM [dbo].[Medical_Data_Dataset]
WHERE sex = 'male'
GROUP BY sex,ROUND(charges,-4)
ORDER BY sex,ROUND(charges,-4)
--Charges distribution female only
SELECT
	DISTINCT sex,
	ROUND(charges,-4) as CHARGE_Bin,
	COUNT (*) AS count_bin
FROM [dbo].[Medical_Data_Dataset]
WHERE sex = 'female'
GROUP BY sex,ROUND(charges,-4)
ORDER BY sex,ROUND(charges,-4)
--Male and Female average charges
SELECT
	DISTINCT sex,
	ROUND(AVG(CAST(charges as float)) OVER (PARTITION BY sex),2) as Avg_charges_sex
FROM [dbo].[Medical_Data_Dataset]
--Smoker Region Totals
SELECT DISTINCT region, smoker, SmokerRegionCount, TotalSmokerCount, SmokerPercentage
FROM (
	SELECT region, smoker,
		COUNT(smoker) OVER (PARTITION BY region, smoker) AS SmokerRegionCount, 
		COUNT(smoker) OVER() AS TotalSmokerCount,
		ROUND((CAST(COUNT(smoker) OVER (PARTITION BY region, smoker) as float) / CAST(COUNT(smoker) OVER() AS float) * 100), 2) AS SmokerPercentage
	FROM [dbo].[Medical_Data_Dataset]
	WHERE smoker = 'true'
) AS subquery
ORDER BY region, smoker, SmokerRegionCount
--Smoker Average Charges
SELECT
	smoker,
	round(avg(cast(charges as float)),2) as Avg_smoker_charges
FROM [dbo].[Medical_Data_Dataset]
GROUP BY smoker
--Comparing charges between smoker and non smoker
SELECT
	ROUND(31885.5/8506.91,2)
--Smoker by region - sex
SELECT DISTINCT sex,region,smoker,SmokerRegionCount,TotalSmokerCount,SmokerPercentage
FROM(
	SELECT sex,region,smoker,
	COUNT(smoker) over(partition by region,sex,smoker) as SmokerRegionCount,
	COUNT(smoker) over() as TotalSmokerCount,
	ROUND((CAST(COUNT(smoker) OVER (PARTITION BY sex,region, smoker) as float) / CAST(COUNT(smoker) OVER() AS float) * 100), 2) AS SmokerPercentage
	FROM [dbo].[Medical_Data_Dataset]
	WHERE smoker = 'true'
	)
	AS subquery
ORDER BY sex,region,SmokerRegionCount
--Children and Charge Correlation
SELECT 
  ROUND(CORR(children, charges),2) AS CORR_CO_Charges
FROM [dbo].[Medical_Data_Dataset]
--Region Median Charges
SELECT DISTINCT region, Region_Median, Overall_Median
FROM (
	SELECT region,
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(charges AS FLOAT)) OVER (PARTITION BY Region),2) AS Region_Median,
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(charges AS FLOAT)) OVER (),2) AS Overall_Median
	FROM [dbo].[Medical_Data_Dataset]
	)
	AS subquery
ORDER BY Region_Median
--BMI Categories
CREATE TABLE #BMI
(
	BMI_Cate VARCHAR(MAX),
	Obese VARCHAR(MAX),
	CHARGES FLOAT,

)
INSERT INTO #BMI (CHARGES,BMI_Cate,Obese)
SELECT 
	charges,
    CASE
        WHEN CAST(BMI AS FLOAT) < 18.5 THEN 'Underweight'
		WHEN CAST(BMI AS FLOAT) >= 18.5 AND CAST(BMI AS FLOAT) < 25 THEN 'Normal'
		WHEN CAST(BMI AS FLOAT) >= 25 AND CAST(BMI AS FLOAT) < 30 THEN 'Overweight'
		WHEN CAST(BMI AS FLOAT) >= 30 THEN 'Obese'
    END,
	CASE 
		WHEN CAST(BMI AS FLOAT) < 30 THEN 'Not Obese'
		WHEN CAST(BMI AS FLOAT) >= 30 THEN 'Obese'
		END 
FROM [dbo].[Medical_Data_Dataset]
SELECT * FROM #BMI
--bmi category charges average
SELECT 
	BMI_Cate,
	ROUND(AVG(charges),2) as Avg_Cost
FROM #BMI
GROUP BY BMI_Cate
ORDER BY ROUND(AVG(charges),2)
--Calculating Avg and Median Charges of BMI Subgroups
SELECT
	DISTINCT Obese,
	ROUND(AVG(charges) OVER(PARTITION BY Obese),2) as Avg_Charges_Obese,
	PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY charges) OVER(PARTITION BY Obese) as Obese_Category_Median
FROM #BMI
--
ALTER TABLE #BMI
ADD SMOKER VARCHAR(MAX);
UPDATE #BMI
SET #BMI.SMOKER = [dbo].[Medical_Data_Dataset].smoker
FROM #BMI
INNER JOIN [dbo].[Medical_Data_Dataset]
ON #BMI.CHARGES = [dbo].[Medical_Data_Dataset].CHARGES;
SELECT * FROM #BMI
--Calculating Avg and Median Charges of BMI Subgroups of smoker only
SELECT
	DISTINCT Obese,
	ROUND(AVG(charges) OVER(PARTITION BY Obese),2) as Avg_Charges_Obese,
	PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY charges) OVER(PARTITION BY Obese) as Obese_Category_Median
FROM #BMI
WHERE SMOKER = 'true'