WITH BASE AS (
    SELECT DISTINCT
         DATE_TRUNC('MONTH',DATETIME_COLUMN) AS MONTHLY --Choose timeframe that suit with your business
        ,CUSTOMER_ID_COLUMN AS CUSTOMER
        ,SUM(REVENUE_COLUMN) AS TOTAL_REVENUE --If you want to see only number of users, this column is optional
    FROM YOUR_TRANSACTIONAL_DATA
    GROUP BY ALL
)
,CALCULATE_TIME_DIFFERENCE AS (
    SELECT DISTINCT
         CUSTOMER
        ,MONTHLY
        ,LAG(MONTHLY) OVER(PARTITION BY CUSTOMER ORDER BY MONTHLY) AS LAG_MONTHLY
        ,DATEDIFF('MONTH',LAG_MONTHLY,MONTHLY) AS MONTH_DIFF --This is a crucial calculation to identify the retention group
        ,TOTAL_REVENUE
    FROM BASE
)
,ASSIGN_GROUP AS (
    SELECT DISTINCT
         CUSTOMER
        ,MONTHLY
        ,CASE
            WHEN MONTH_DIFF IS NULL THEN 'New' --There is no previous month. Current month is their first month ever
            WHEN MONTH_DIFF = 1 THEN 'Repeat' --Previous month is last month so they are repeatedly active 2 months consecutive
            WHEN MONTH_DIFF > 1 THEN 'Return' --They are inactive for atleast a month before coming back
            ELSE 'Please Check' --In case we miscalculate
         END AS RETENTION_GROUP
        ,TOTAL_REVENUE
    FROM CALCULATE_TIME_DIFFERENCE
)
,SUMMARIZE AS (
    SELECT DISTINCT
         MONTHLY
        ,RETENTION_GROUP
        ,COUNT(DISTINCT CUSTOMER) AS NUMBER_OF_CUSTOMERS
        ,SUM(TOTAL_REVENUE) AS TOTAL_REVENUE
    FROM ASSIGN_GROUP
    GROUP BY ALL
)
SELECT * FROM SUMMARIZE
