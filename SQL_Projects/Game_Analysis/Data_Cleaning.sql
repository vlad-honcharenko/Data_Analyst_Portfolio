-- 1. Drop if table exists
DROP TABLE IF EXISTS game_payments_cleaned;

-- 2. New cleaned table using a CTE
CREATE TABLE game_payments_cleaned AS

-- 3. Drop NULL rows
WITH filtered_data AS (
    SELECT *
    FROM game_payments
    WHERE revenue_amount_usd IS NOT NULL
),

-- 4. Replace NULL values with 'Unknown'
platform_filled AS (
    SELECT
        user_id,
        game_name,
        payment_date,
        revenue_amount_usd,
        COALESCE(platform, 'Unknown') AS platform,
        session_duration_minutes,
        country
    FROM filtered_data
),

-- 5. Median session duration (without NULLs)
median_cte AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY session_duration_minutes) AS median_val
    FROM platform_filled
    WHERE session_duration_minutes IS NOT NULL
),

-- 6. NULLs replacing
final_cleaned AS (
    SELECT
        pf.user_id,
        pf.game_name,
        pf.payment_date::timestamp AS payment_date,
        pf.revenue_amount_usd,
        pf.platform,
        COALESCE(pf.session_duration_minutes, m.median_val) AS session_duration_minutes,
        pf.country
    FROM platform_filled pf
    CROSS JOIN median_cte m
)

-- 5. Final cleaned table
SELECT
    user_id,
    game_name,
    payment_date,
    revenue_amount_usd,
    platform,
    session_duration_minutes,
    country,
    TRIM(SPLIT_PART(country, ',', 1)) AS city,
    TRIM(SPLIT_PART(country, ',', 2)) AS country_cleaned
FROM final_cleaned
WHERE session_duration_minutes <= 300
;
