-- Create temporary tables for intermediate results
CREATE TABLE #ClassificationCounts (
    CLASIFFICATION_FINAL INT,
    ClassificationCount INT
);

CREATE TABLE #GenderAgeGroupCounts (
    Gender NVARCHAR(10),
    AgeGroup NVARCHAR(10),
    DemographicCount INT
);

CREATE TABLE #MortalityRates (
    Gender NVARCHAR(10),
    MortalityRate FLOAT
);

CREATE TABLE #ResourceUsage (
    Resource NVARCHAR(10),
    UsageRate FLOAT
);

CREATE TABLE #ComorbidityMortality (
    Condition NVARCHAR(15),
    ConditionValue INT,
    MortalityRate FLOAT
);

-- Populate #ClassificationCounts
INSERT INTO #ClassificationCounts
SELECT 
    CLASIFFICATION_FINAL, 
    COUNT(*) AS ClassificationCount
FROM dbo.Covid19_Data
GROUP BY CLASIFFICATION_FINAL;

-- Populate #GenderAgeGroupCounts
INSERT INTO #GenderAgeGroupCounts
SELECT 
    CASE SEX 
        WHEN 1 THEN 'Male' 
        WHEN 2 THEN 'Female' 
        ELSE 'Other' 
    END AS Gender,
    CASE 
        WHEN AGE BETWEEN 0 AND 18 THEN '0-18'
        WHEN AGE BETWEEN 19 AND 30 THEN '19-30'
        WHEN AGE BETWEEN 31 AND 50 THEN '31-50'
        WHEN AGE BETWEEN 51 AND 70 THEN '51-70'
        WHEN AGE > 70 THEN '71+'
        ELSE 'Unknown' 
    END AS AgeGroup,
    COUNT(*) AS DemographicCount
FROM dbo.Covid19_Data
GROUP BY SEX, 
    CASE 
        WHEN AGE BETWEEN 0 AND 18 THEN '0-18'
        WHEN AGE BETWEEN 19 AND 30 THEN '19-30'
        WHEN AGE BETWEEN 31 AND 50 THEN '31-50'
        WHEN AGE BETWEEN 51 AND 70 THEN '51-70'
        WHEN AGE > 70 THEN '71+'
        ELSE 'Unknown'
    END;

-- Populate #MortalityRates
INSERT INTO #MortalityRates
SELECT 
    CASE SEX 
        WHEN 1 THEN 'Male' 
        WHEN 2 THEN 'Female' 
        ELSE 'Other' 
    END AS Gender,
    (SUM(CASE WHEN DATE_DIED != '9999-99-99' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS MortalityRate
FROM dbo.Covid19_Data
GROUP BY SEX;

-- Populate #ResourceUsage
INSERT INTO #ResourceUsage
SELECT 
    'Intubated' AS Resource,
    (SUM(CASE WHEN INTUBED = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS UsageRate
FROM dbo.Covid19_Data
UNION ALL
SELECT 
    'ICU' AS Resource,
    (SUM(CASE WHEN ICU = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS UsageRate
FROM dbo.Covid19_Data;

-- Populate #ComorbidityMortality
INSERT INTO #ComorbidityMortality
SELECT 
    'Diabetes' AS Condition,
    DIABETES AS ConditionValue,
    (SUM(CASE WHEN DATE_DIED != '9999-99-99' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS MortalityRate
FROM dbo.Covid19_Data
GROUP BY DIABETES
UNION ALL
SELECT 
    'Hypertension' AS Condition,
    HIPERTENSION AS ConditionValue,
    (SUM(CASE WHEN DATE_DIED != '9999-99-99' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS MortalityRate
FROM dbo.Covid19_Data
GROUP BY HIPERTENSION
UNION ALL
SELECT 
    'Obesity' AS Condition,
    OBESITY AS ConditionValue,
    (SUM(CASE WHEN DATE_DIED != '9999-99-99' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS MortalityRate
FROM dbo.Covid19_Data
GROUP BY OBESITY
UNION ALL
SELECT 
    'Cardiovascular' AS Condition,
    CARDIOVASCULAR AS ConditionValue,
    (SUM(CASE WHEN DATE_DIED != '9999-99-99' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS MortalityRate
FROM dbo.Covid19_Data
GROUP BY CARDIOVASCULAR;

-- Final SELECT to create a consolidated view of the data
SELECT 
    cc.CLASIFFICATION_FINAL,
    cc.ClassificationCount,
    gag.Gender,
    gag.AgeGroup,
    gag.DemographicCount,
    mr.MortalityRate AS GenderMortalityRate,
    ru.Resource,
    ru.UsageRate,
    cm.Condition,
    cm.ConditionValue,
    cm.MortalityRate AS ConditionMortalityRate,
    CASE 
        WHEN cd.DATE_DIED = '9999-99-99' THEN NULL
        ELSE CONVERT(varchar, cd.DATE_DIED, 23)
    END AS DateDied, -- Ensure DATE_DIED is formatted as YYYY-MM-DD
    CASE 
        WHEN cd.DATE_DIED = '9999-99-99' THEN 'Alive'
        ELSE 'Deceased'
    END AS AliveStatus
FROM #ClassificationCounts cc
LEFT JOIN #GenderAgeGroupCounts gag ON 1=1 -- Cartesian join for independent aggregates
LEFT JOIN #MortalityRates mr ON 1=1
LEFT JOIN #ResourceUsage ru ON 1=1
LEFT JOIN #ComorbidityMortality cm ON 1=1
LEFT JOIN dbo.Covid19_Data cd ON cc.CLASIFFICATION_FINAL = cd.CLASIFFICATION_FINAL
ORDER BY cc.CLASIFFICATION_FINAL, gag.Gender, gag.AgeGroup, ru.Resource;

-- Drop temporary tables
DROP TABLE #ClassificationCounts;
DROP TABLE #GenderAgeGroupCounts;
DROP TABLE #MortalityRates;
DROP TABLE #ResourceUsage;
DROP TABLE #ComorbidityMortality;
