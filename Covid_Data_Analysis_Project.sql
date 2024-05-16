WITH ClassificationCounts AS (
    SELECT 
        CLASIFFICATION_FINAL, 
        COUNT(*) AS NumberOfCases
    FROM dbo.Covid_Data
    GROUP BY CLASIFFICATION_FINAL
),
GenderAgeGroupCounts AS (
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
        COUNT(*) AS NumberOfCases
    FROM dbo.Covid_Data
    GROUP BY SEX, 
        CASE 
            WHEN AGE BETWEEN 0 AND 18 THEN '0-18'
            WHEN AGE BETWEEN 19 AND 30 THEN '19-30'
            WHEN AGE BETWEEN 31 AND 50 THEN '31-50'
            WHEN AGE BETWEEN 51 AND 70 THEN '51-70'
            WHEN AGE > 70 THEN '71+'
            ELSE 'Unknown'
        END
),
MortalityRates AS (
    SELECT 
        CASE SEX 
            WHEN 1 THEN 'Male' 
            WHEN 2 THEN 'Female' 
            ELSE 'Other' 
        END AS Gender,
        (SUM(CASE WHEN DATE_DIED != '9999-99-99' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS MortalityRate
    FROM dbo.Covid_Data
    GROUP BY SEX
),
ResourceUsage AS (
    SELECT 
        'Intubated' AS Resource,
        (SUM(CASE WHEN INTUBED = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS UsageRate
    FROM dbo.Covid_Data
    UNION ALL
    SELECT 
        'ICU' AS Resource,
        (SUM(CASE WHEN ICU = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) AS UsageRate
    FROM dbo.Covid_Data
)
SELECT 
    a.CLASIFFICATION_FINAL,
    a.NumberOfCases AS ClassificationCount,
    b.Gender,
    b.AgeGroup,
    b.NumberOfCases AS DemographicCount,
    c.MortalityRate,
    d.Resource,
    d.UsageRate
FROM ClassificationCounts a
CROSS JOIN GenderAgeGroupCounts b
CROSS JOIN MortalityRates c
CROSS JOIN ResourceUsage d
ORDER BY a.CLASIFFICATION_FINAL, b.Gender, b.AgeGroup, d.Resource;
