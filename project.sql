USE hw;
-- Query 1: Compares depression, anxiety, and bipolar disorder prevalences among males from 2010 to 2019
-- for countries with high depression or anxiety  or bipolar rates.
SELECT 
    depression.Entity, 
    depression.Year, 
    depression.`Prevalence-Male` AS Male_Depression_Prevalence, 
    anxiety.`Prevalence-Male` AS Male_Anxiety_Prevalence, 
    bipolar.`Prevalence-Male` AS Male_Bipolar_Prevalence
FROM 
    depression
JOIN 
    anxiety ON depression.Entity = anxiety.Entity AND depression.Year = anxiety.Year
JOIN 
    bipolar ON depression.Entity = bipolar.Entity AND depression.Year = bipolar.Year
WHERE 
    depression.Year BETWEEN 2010 AND 2019
    AND (depression.`Prevalence-Male` > 3 OR anxiety.`Prevalence-Male` > 3 OR Bipolar.`Prevalence-Male` > 2)


-- Query 2: Countries with Higher Female Anxiety Prevalence Compared to Males
SELECT 
    anxiety.Year,
    anxiety.Entity AS CountryName, 
    anxiety.`Prevalence-Female` AS FemaleAnxietyPrevalence,
    anxiety.`Prevalence-Male` AS MaleAnxietyPrevalence
FROM 
    anxiety
WHERE  
    anxiety.`Prevalence-Female` > anxiety.`Prevalence-Male`
    AND anxiety.`Prevalence-Female` IS NOT NULL
    AND anxiety.`Prevalence-Male` IS NOT NULL
ORDER BY 
    (anxiety.`Prevalence-Female` - anxiety.`Prevalence-Male`) DESC;


-- Query 3: Countries with Significant Variation in Schizophrenia Prevalence Over Years
-- running time 1.016 sec
SELECT DISTINCT s.Entity AS Country,
       MAX(yearlyDiff.MaxYearlyPrevalence) - MIN(yearlyDiff.MinYearlyPrevalence) AS YearlyPrevalenceDifference
FROM schizophrenia s
JOIN (
  SELECT Entity, 
         MAX(`Prevalence-Male` + `Prevalence-Female`) AS MaxYearlyPrevalence,
         MIN(`Prevalence-Male` + `Prevalence-Female`) AS MinYearlyPrevalence
  FROM schizophrenia
  GROUP BY Entity
) AS yearlyDiff ON s.Entity = yearlyDiff.Entity
GROUP BY s.Entity
ORDER BY YearlyPrevalenceDifference DESC;


-- Query 3 optimization running time 0.187 sec
SELECT 
    Entity AS Country,
    MAX(`Prevalence-Male` + `Prevalence-Female`) - MIN(`Prevalence-Male` + `Prevalence-Female`) AS YearlyPrevalenceDifference
FROM 
    schizophrenia
GROUP BY 
    Entity
ORDER BY 
    YearlyPrevalenceDifference DESC;


-- Query 4: Average Prevalence of Disorders by Country and Gender, and Differences
-- running time 0.703 sec
SELECT 
    Entity AS Country, 
    Gender, 
    AVG(Prevalence) AS AvgPrevalence
FROM
    (
        SELECT 
            Entity, 
            'Male' AS Gender, 
            `Prevalence-Male` AS Prevalence
        FROM anxiety

        UNION ALL

        SELECT 
            Entity, 
            'Female' AS Gender, 
            `Prevalence-Female` AS Prevalence
        FROM anxiety
    ) AS combined
GROUP BY 
    Entity, Gender
ORDER BY 
    AvgPrevalence DESC;

-- Query 4 (optimizing) running time 0.266 sec
SELECT 
    anxiety.Entity AS Country, 
    'Male' AS Gender, 
    AVG(anxiety.`Prevalence-Male`) AS AvgPrevalence
FROM anxiety
GROUP BY anxiety.Entity

UNION ALL

SELECT 
    anxiety.Entity AS Country, 
    'Female' AS Gender, 
    AVG(anxiety.`Prevalence-Female`) AS AvgPrevalence
FROM anxiety
GROUP BY anxiety.Entity
ORDER BY 
    AvgPrevalence DESC;
    

-- Query 5 prevalence per capita of five different disorders among males
SELECT 
    depression.Entity AS Country,
    SUM(depression.`Prevalence-Male` * depression.`Population (historical estimates)`) / SUM(depression.`Population (historical estimates)`) AS DepressionPrevalencePerCapita,
    SUM(anxiety.`Prevalence-Male` * anxiety.`Population (historical estimates)`) / SUM(anxiety.`Population (historical estimates)`) AS AnxietyPrevalencePerCapita,
    SUM(bipolar.`Prevalence-Male` * bipolar.`Population (historical estimates)`) / SUM(bipolar.`Population (historical estimates)`) AS BipolarPrevalencePerCapita,
    SUM(schizophrenia.`Prevalence-Male` * schizophrenia.`Population (historical estimates)`) / SUM(schizophrenia.`Population (historical estimates)`) AS SchizophreniaPrevalencePerCapita,
    SUM(eating.`Prevalence-Male` * eating.`Population (historical estimates)`) / SUM(eating.`Population (historical estimates)`) AS EatingDisordersPrevalencePerCapita
FROM 
    depression
JOIN 
    anxiety ON depression.Entity = anxiety.Entity AND depression.Year = anxiety.Year
JOIN 
    bipolar ON depression.Entity = bipolar.Entity AND depression.Year = bipolar.Year 
JOIN
    schizophrenia ON depression.Entity = schizophrenia.Entity AND depression.Year = schizophrenia.Year
JOIN
    eating ON depression.Entity = eating.Entity AND depression.Year = eating.Year
GROUP BY 
    depression.Entity
ORDER BY 
    DepressionPrevalencePerCapita DESC
LIMIT 100;


-- Query 6 : Yearly Increase in Schizophrenia Prevalence among Males
SELECT 
    earlier.Entity AS CountryName,
    earlier.Year AS YearOne,
    later.Year AS YearTwo,
    earlier.`Prevalence-Male` AS PrevalenceYearOne,
    later.`Prevalence-Male` AS PrevalenceYearTwo,
    CASE
        WHEN later.`Prevalence-Male` > earlier.`Prevalence-Male` THEN '↗'  -- Ascending
        WHEN later.`Prevalence-Male` < earlier.`Prevalence-Male` THEN '↘'  -- Descending
        ELSE '→'  -- Stable
    END AS Trend
FROM 
    schizophrenia as earlier
JOIN 
    schizophrenia as later 
    ON earlier.Entity = later.Entity 
    AND later.Year = earlier.Year + 1
WHERE 
    later.`Prevalence-Male` > earlier.`Prevalence-Male`;

-- Query 7 Difference in Eating Disorders Prevalence Range by Continent
SELECT DISTINCT e.Continent, 
       MAX(rangeDiff.MaxPrevalence) - MIN(rangeDiff.MinPrevalence) AS PrevalenceRangeDifference
FROM eating e
JOIN (
  SELECT Continent, 
         MAX(`Prevalence-Male` + `Prevalence-Female`) AS MaxPrevalence,
         MIN(`Prevalence-Male` + `Prevalence-Female`) AS MinPrevalence
  FROM eating
  GROUP BY Continent
) AS rangeDiff ON e.Continent = rangeDiff.Continent
GROUP BY e.Continent



-- Query 8: Countries with the Largest Gender Disparity in Bipolar Disorder Prevalence
-- running time 0.703 sec 
SELECT 
    Entity AS Country,
    MAX(ABS(MalePrevalence - FemalePrevalence)) AS MaxGenderDisparity
FROM 
    (SELECT 
        Entity,
        Year,
        MAX(`Prevalence-Male`) AS MalePrevalence,
        MAX(`Prevalence-Female`) AS FemalePrevalence
    FROM 
        bipolar
    GROUP BY 
        Entity, Year) AS YearlyData
GROUP BY 
    Entity
ORDER BY 
    MaxGenderDisparity DESC
LIMIT 1000;

-- Query 8 optimized running time 0.515 sec
SELECT 
    Entity AS Country,
    MAX(YearlyGenderDisparity) AS MaxGenderDisparity
FROM 
    (SELECT 
        Entity,
        ABS(MAX(`Prevalence-Male`) - MAX(`Prevalence-Female`)) AS YearlyGenderDisparity
    FROM 
        bipolar
    GROUP BY 
        Entity, Year) AS YearlyData
GROUP BY 
    Entity
ORDER BY 
    MaxGenderDisparity DESC
LIMIT 1000;


-- Query 9 Average Bipolar Disorder Prevalence with Severity Status

SELECT 
    Entity AS Country, 
    AVG(`Prevalence-Male`) AS AvgMaleBipolar, 
    CASE
        WHEN AVG(`Prevalence-Male`) > 1 THEN 'High Risk'
        WHEN AVG(`Prevalence-Male`) > 0.5 AND AVG(`Prevalence-Male`) <= 1 THEN 'Moderate Risk'
        WHEN AVG(`Prevalence-Male`) <= 0.5 THEN 'Low Risk'
    END AS RiskLevel
FROM bipolar
GROUP BY Entity
ORDER BY AvgMaleBipolar DESC;

-- Query 10 Classifying Schizophrenia Prevalence Levels by Continent

SELECT 
    Continent,
    AVG(`Prevalence-Male` + `Prevalence-Female`) / 2 AS AvgSchizophreniaPrevalence,
    CASE
        WHEN AVG(`Prevalence-Male` + `Prevalence-Female`) / 2 > 0.3 THEN 'High Prevalence'
        WHEN AVG(`Prevalence-Male` + `Prevalence-Female`) / 2 > 0.2 AND AVG(`Prevalence-Male` + `Prevalence-Female`) / 2 <= 0.3 THEN 'Moderate Prevalence'
        WHEN AVG(`Prevalence-Male` + `Prevalence-Female`) / 2 <= 0.2 THEN 'Low Prevalence'
    END AS PrevalenceLevel
FROM 
    schizophrenia
WHERE 
    Continent IS NOT NULL
GROUP BY 
    Continent
ORDER BY 
    AvgSchizophreniaPrevalence DESC;
