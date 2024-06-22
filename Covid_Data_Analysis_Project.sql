#Create temporary tables for intermediate results
CREATE TABLE #TempClassificationCounts (
    Classification INT,
    Count INT
);

CREATE TABLE #TempGenderAgeGroups (
    Gender NVARCHAR(10),
    AgeGroup NVARCHAR(10),
    Count INT
);

CREATE TABLE #TempMortalityRates (
    Gender NVARCHAR(10),
    MortalityRate FLOAT
);

CREATE TABLE #TempResourceUsage (
    Resource NVARCHAR(10),
    UsageRate FLOAT
);

CREATE TABLE #TempComorbidityMortality (
    Condition NVARCHAR(15),
    ConditionValue INT,
    MortalityRate FLOAT
);

-- Populate #TempClassificationCounts
INSERT INTO #TempClassificationCounts
SELECT 
    CLASIFFICATION_FINAL, 
    COUNT(*) AS Count
FROM dbo.Covid19_Data
GROUP BY CLASIFFICATION_FINAL;

#Populate #TempGenderAgeGroups
INSERT INTO #TempGenderAgeGroups
SELECT 
    CASE 
        WHEN SEX = 1 THEN 'Male' 
        WHEN SEX = 2 THEN 'Female' 
        ELSE 'Other' 
    END AS Gender,
    CASE 
        WHEN AGE BETWEEN 0 AND 18 THEN '0-18'
        WHEN AGE BETWEEN 19 AND 30 THEN '19-30'
        WHEN AGE BETWEEN 31 AND 50 THEN '31-50'
        WHEN AGE BETWEEN 51 AND 70 THEN '51-70'
        ELSE '71+' 
    END AS AgeGroup,
    COUNT(*) AS Count
FROM dbo.Covid19_Data
GROUP BY SEX, 
    CASE 
        WHEN AGE BETWEEN 0 AND 18 THEN '0-18'
        WHEN AGE BETWEEN 19 AND 30 THEN '19-30'
        WHEN AGE BETWEEN 31 AND 50 THEN '31-50'
        WHEN AGE BETWEEN 51 AND 70 THEN '51-70'
        ELSE '71+' 
    END;

#Populate #TempMortalityRates
INSERT INTO #TempMortalityRates
SELECT 
    CASE 
        WHEN SEX = 1 THEN 'Male' 
        WHEN SEX = 2 THEN 'Female' 
        ELSE 'Other' 
    END AS Gender,
    (SUM(CASE WHEN DATE_DIED != '9999-99-99' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS MortalityRate
FROM dbo.Covid19_Data
GROUP BY SEX;

#Populate #TempResourceUsage
INSERT INTO #TempResourceUsage
SELECT 
    'Intubated' AS Resource,
    (SUM(CASE WHEN INTUBED = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS UsageRate
FROM dbo.Covid19_Data
UNION ALL
SELECT 
    'ICU' AS Resource,
    (SUM(CASE WHEN ICU = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS UsageRate
FROM dbo.Covid19_Data;

#Populate #TempComorbidityMortality
INSERT INTO #TempComorbidityMortality
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
    OBESIDAD AS ConditionValue,
    (SUM(CASE WHEN DATE_DIED != '9999-99-99' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS MortalityRate
FROM dbo.Covid19_Data
GROUP BY OBESIDAD
UNION ALL
SELECT 
    'Cardiovascular' AS Condition,
    CARDIOVASCULAR AS ConditionValue,
    (SUM(CASE WHEN DATE_DIED != '9999-99-99' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS MortalityRate
FROM dbo.Covid19_Data
GROUP BY CARDIOVASCULAR;

#Final SELECT to create a consolidated view of the data
SELECT 
    cc.Classification,
    cc.Count AS ClassificationCount,
    gag.Gender,
    gag.AgeGroup,
    gag.Count AS DemographicCount,
    mr.MortalityRate AS GenderMortalityRate,
    ru.Resource,
    ru.UsageRate,
    cm.Condition,
    cm.ConditionValue,
    cm.MortalityRate AS ConditionMortalityRate,
    CASE 
        WHEN cd.DATE_DIED = '9999-99-99' THEN NULL
        ELSE CONVERT(varchar, cd.DATE_DIED, 23)
    END AS DateDied,
    CASE 
        WHEN cd.DATE_DIED = '9999-99-99' THEN 'Alive'
        ELSE 'Deceased'
    END AS AliveStatus
FROM #TempClassificationCounts cc
LEFT JOIN #TempGenderAgeGroups gag ON 1=1
LEFT JOIN #TempMortalityRates mr ON 1=1
LEFT JOIN #TempResourceUsage ru ON 1=1
LEFT JOIN #TempComorbidityMortality cm ON 1=1
LEFT JOIN dbo.Covid19_Data cd ON cc.Classification = cd.CLASIFFICATION_FINAL
ORDER BY cc.Classification, gag.Gender, gag.AgeGroup, ru.Resource;

#Drop temporary tables
DROP TABLE #TempClassificationCounts;
DROP TABLE #TempGenderAgeGroups;
DROP TABLE #TempMortalityRates;
DROP TABLE #TempResourceUsage;
DROP TABLE #TempComorbidityMortality;
