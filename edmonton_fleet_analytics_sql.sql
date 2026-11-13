CREATE DATABASE edmonton_fleet_analytics;
USE edmonton_fleet_analytics;

SELECT COUNT(*) AS total_records
FROM fleet_activity;

SELECT
    YEAR(period) AS year,
    ROUND(SUM(`kilometers driven`), 2) AS total_km
FROM fleet_activity
GROUP BY YEAR(period)
ORDER BY year;

WITH annual_fleet AS (
    SELECT
        YEAR(period) AS year,
        SUM(`kilometers driven`) AS total_km
    FROM fleet_activity
    GROUP BY YEAR(period)
)
SELECT
    year,
    ROUND(total_km, 2) AS total_km,
    ROUND(
        LAG(total_km) OVER (ORDER BY year), 2
    ) AS previous_year_km
FROM annual_fleet
ORDER BY year;

WITH annual_fleet AS (
    SELECT
        YEAR(period) AS year,
        SUM(`kilometers driven`) AS total_km
    FROM fleet_activity
    GROUP BY YEAR(period)
)
SELECT
    year,
    ROUND(total_km, 2) AS total_km,
    ROUND(
        100 * (
            total_km - LAG(total_km) OVER (ORDER BY year)
        ) / LAG(total_km) OVER (ORDER BY year),
        2
    ) AS yoy_growth_pct
FROM annual_fleet
ORDER BY year;

WITH department_activity AS (
    SELECT
        department,
        `asset class` AS asset_class,
        YEAR(period) AS year,
        SUM(`kilometers driven`) AS total_km
    FROM fleet_activity
    GROUP BY
        department,
        `asset class`,
        YEAR(period)
)
SELECT
    department,
    asset_class,
    year,
    ROUND(total_km, 2) AS total_km
FROM department_activity
ORDER BY department, asset_class, year;


WITH department_activity AS (
    SELECT
        department,
        `asset class` AS asset_class,
        YEAR(period) AS year,
        SUM(`kilometers driven`) AS total_km
    FROM fleet_activity
    GROUP BY department, `asset class`, YEAR(period)
)
SELECT
    department,
    asset_class,
    year,
    total_km,
    LAG(total_km) OVER (
        PARTITION BY department, asset_class
        ORDER BY year
    ) AS previous_year_km
FROM department_activity
ORDER BY department, asset_class, year;


WITH department_activity AS (
    SELECT
        department,
        `asset class` AS asset_class,
        YEAR(period) AS year,
        SUM(`kilometers driven`) AS total_km
    FROM fleet_activity
    GROUP BY department, `asset class`, YEAR(period)
),
previous_activity AS (
    SELECT
        department,
        asset_class,
        year,
        total_km,
        LAG(total_km) OVER (
            PARTITION BY department, asset_class
            ORDER BY year
        ) AS previous_year_km,
        LAG(year) OVER (
            PARTITION BY department, asset_class
            ORDER BY year
        ) AS previous_year
    FROM department_activity
)
SELECT
    department,
    asset_class,
    year,
    ROUND(
        (total_km - previous_year_km)
        / NULLIF(previous_year_km, 0) * 100,
        2
    ) AS yoy_change_pct
FROM previous_activity
WHERE year = previous_year + 1
ORDER BY ABS(
    (total_km - previous_year_km)
    / NULLIF(previous_year_km, 0)
) DESC;


SELECT
    department,
    asset_class,
    year,
    ROUND(
        (total_km - previous_year_km)
        / NULLIF(previous_year_km, 0) * 100,
        2
    ) AS yoy_change_pct,
    DENSE_RANK() OVER (
        ORDER BY ABS(
            (total_km - previous_year_km)
            / NULLIF(previous_year_km, 0)
        ) DESC
    ) AS investigation_rank
FROM previous_activity
WHERE year = previous_year + 1
  AND previous_year_km > 0
ORDER BY investigation_rank
LIMIT 10;



CREATE OR REPLACE VIEW vw_fleet_annual_activity AS
SELECT
    department,
    `asset class` AS asset_class,
    YEAR(period) AS report_year,
    SUM(`kilometers driven`) AS total_km,
    COUNT(DISTINCT DATE_FORMAT(period, '%Y-%m')) AS months_reported
FROM fleet_activity
GROUP BY department, `asset class`, YEAR(period);


CREATE OR REPLACE VIEW vw_fleet_yoy AS
SELECT
    cur.department,
    cur.asset_class,
    cur.report_year,
    cur.total_km,
    cur.months_reported,
    prev.total_km AS previous_year_km,
    prev.months_reported AS previous_year_months,
    cur.total_km - prev.total_km AS km_change,
    100.0 * (cur.total_km - prev.total_km)
        / NULLIF(prev.total_km, 0) AS pct_change
FROM vw_fleet_annual_activity cur
LEFT JOIN vw_fleet_annual_activity prev
    ON cur.department = prev.department
    AND cur.asset_class = prev.asset_class
    AND cur.report_year = prev.report_year + 1;


CREATE OR REPLACE VIEW vw_fleet_three_year_summary AS
SELECT
    department,
    asset_class,
    MAX(CASE WHEN report_year = 2012 THEN total_km END) AS km_2012,
    MAX(CASE WHEN report_year = 2013 THEN total_km END) AS km_2013,
    MAX(CASE WHEN report_year = 2014 THEN total_km END) AS km_2014,
    MAX(CASE WHEN report_year = 2012 THEN months_reported END) AS months_2012,
    MAX(CASE WHEN report_year = 2013 THEN months_reported END) AS months_2013,
    MAX(CASE WHEN report_year = 2014 THEN months_reported END) AS months_2014,
    CASE
        WHEN MAX(CASE WHEN report_year = 2012 THEN months_reported END) = 12
         AND MAX(CASE WHEN report_year = 2013 THEN months_reported END) = 12
         AND MAX(CASE WHEN report_year = 2014 THEN months_reported END) = 12
        THEN 'Complete'
        ELSE 'Review coverage'
    END AS coverage_status
FROM vw_fleet_annual_activity
GROUP BY department, asset_class;


SELECT
    coverage_status,
    COUNT(*) AS combinations
FROM vw_fleet_three_year_summary
GROUP BY coverage_status;


SELECT
    department,
    asset_class,
    months_2012,
    months_2013,
    months_2014
FROM vw_fleet_three_year_summary
WHERE coverage_status = 'Review coverage'
ORDER BY department, asset_class;


CREATE OR REPLACE VIEW vw_fleet_investigation_ranking AS
WITH changes AS (
    SELECT
        department,
        asset_class,
        km_2012,
        km_2013,
        km_2014,
        km_2014 - km_2012 AS km_change,
        100.0 * (km_2014 - km_2012)
            / NULLIF(km_2012, 0) AS pct_change,
        ABS(km_2014 - km_2012) AS abs_km_change,
        ABS(
            100.0 * (km_2014 - km_2012)
            / NULLIF(km_2012, 0)
        ) AS abs_pct_change
    FROM vw_fleet_three_year_summary
    WHERE coverage_status = 'Complete'
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY abs_km_change) AS km_rank,
        COUNT(*) OVER (PARTITION BY abs_km_change) AS km_tie_count,
        RANK() OVER (ORDER BY abs_pct_change) AS pct_rank,
        COUNT(*) OVER (PARTITION BY abs_pct_change) AS pct_tie_count,
        COUNT(*) OVER () AS total_combinations
    FROM changes
    WHERE pct_change IS NOT NULL
)
SELECT
    department,
    asset_class,
    km_2012,
    km_2013,
    km_2014,
    km_change,
    pct_change,
    abs_km_change,
    abs_pct_change,
    50.0 * (
        (km_rank + (km_tie_count - 1) / 2.0) / total_combinations
        +
        (pct_rank + (pct_tie_count - 1) / 2.0) / total_combinations
    ) AS priority_score
FROM ranked;


SELECT
    department,
    asset_class,
    ROUND(km_change, 2) AS km_change,
    ROUND(pct_change, 2) AS pct_change,
    ROUND(priority_score, 2) AS priority_score
FROM vw_fleet_investigation_ranking
ORDER BY priority_score DESC
LIMIT 10;


WITH dept_asset AS (
    SELECT
        department,
        asset_class,
        report_year,
        total_km
    FROM vw_fleet_annual_activity
    WHERE department IN (
        'Edmonton Police Service',
        'Community Services - Parking Enforcement'
    )
)
SELECT
    department,
    report_year,
    asset_class,
    ROUND(total_km, 2) AS total_km,
    ROUND(
        100.0 * total_km /
        NULLIF(
            SUM(total_km) OVER (
                PARTITION BY department, report_year
            ), 0
        ), 2
    ) AS activity_share_pct
FROM dept_asset
ORDER BY department, report_year, asset_class;


SELECT
    department,
    asset_class,
    report_year,
    ROUND(km_change, 2) AS km_change,
    ROUND(pct_change, 2) AS pct_change
FROM vw_fleet_yoy
WHERE months_reported = 12
  AND previous_year_months = 12
  AND pct_change IS NOT NULL
ORDER BY ABS(pct_change) DESC
LIMIT 20;


WITH annual_totals AS (
    SELECT
        YEAR(period) AS report_year,
        SUM(`kilometers driven`) AS total_km
    FROM fleet_activity
    GROUP BY YEAR(period)
),
annual_with_lag AS (
    SELECT
        report_year,
        total_km,
        LAG(total_km) OVER (
            ORDER BY report_year
        ) AS previous_km
    FROM annual_totals
)
SELECT
    report_year,
    ROUND(total_km, 2) AS total_km,
    ROUND(
        100.0 * (total_km - previous_km)
        / NULLIF(previous_km, 0), 2
    ) AS yoy_growth_pct
FROM annual_with_lag
ORDER BY report_year;


SELECT *
FROM vw_fleet_annual_activity
ORDER BY department, asset_class, report_year;

SELECT *
FROM vw_fleet_yoy
ORDER BY department, asset_class, report_year;

SELECT *
FROM vw_fleet_three_year_summary
ORDER BY department, asset_class;

SELECT *
FROM vw_fleet_investigation_ranking
ORDER BY priority_score DESC;



SELECT
    (SELECT COUNT(*)
     FROM fleet_activity) AS total_records,

    (SELECT COUNT(*)
     FROM vw_fleet_three_year_summary
     WHERE coverage_status = 'Complete') AS complete_combinations,

    (SELECT COUNT(*)
     FROM vw_fleet_three_year_summary
     WHERE coverage_status = 'Review coverage') AS incomplete_combinations,

    (SELECT ROUND(MAX(priority_score), 2)
     FROM vw_fleet_investigation_ranking) AS highest_priority_score;
