-- 🔹 User Behaviour:
-- Comparing avg revenue to each bucket group.
SELECT 
  CASE 
      WHEN session_duration_minutes < 10 THEN '0-10 mins'
      WHEN session_duration_minutes < 30 THEN '10-30 mins'
      WHEN session_duration_minutes < 60 THEN '30-60 mins'
      ELSE '60+ mins'
  END AS session_duration_bucket,
  AVG(revenue_amount_usd) AS avg_revenue
FROM game_payments_cleaned
GROUP BY session_duration_bucket
ORDER BY session_duration_bucket;

-- Whether longer session durations correlate with higher spending per user.
SELECT user_id, 
       AVG(session_duration_minutes) AS avg_session, 
       SUM(revenue_amount_usd) AS total_spent
FROM game_payments_cleaned
GROUP BY user_id
ORDER BY total_spent DESC;

--  Correlation.
SELECT CORR(session_duration_minutes, revenue_amount_usd) AS session_revenue_corr
FROM game_payments_cleaned;

-- 🔹 Churn Risk:
-- Churned users.
WITH last_payments AS (
    SELECT user_id, 
           MAX(payment_date) AS last_payment
    FROM game_payments_cleaned
    GROUP BY user_id
)
SELECT * FROM last_payments
WHERE last_payment < CURRENT_DATE - INTERVAL '30 days';

-- Drop-off patterns after last payment.
SELECT user_id,
       COUNT(*) AS session_count,
       MAX(payment_date) AS last_payment
FROM game_payments_cleaned
GROUP BY user_id
ORDER BY last_payment;

-- High session durations users without recent payments.
SELECT 
      user_id,
      MAX(payment_date) AS last_payment,
      AVG(session_duration_minutes) AS avg_session_duration
FROM game_payments_cleaned
GROUP BY user_id
HAVING MAX(payment_date) < '2025-04-15'
   AND AVG(session_duration_minutes) > 30
ORDER BY avg_session_duration DESC;

-- 🔹 Power Users:
-- Top paying users.
SELECT user_id,
       COUNT(*) AS total_payments,
       SUM(revenue_amount_usd) AS total_spent
FROM game_payments_cleaned
GROUP BY user_id
ORDER BY total_spent DESC;

-- Most active users by session duration.
SELECT 
      user_id,
      SUM(session_duration_minutes) AS total_play_time,
      COUNT(*) AS sessions
FROM game_payments_cleaned
GROUP BY user_id
ORDER BY total_play_time DESC
LIMIT 10;

-- 🔹 Revenue & Engagement per game:
-- Sum revenue, ARPU, RPS, session duration per game.
SELECT game_name,
       SUM(revenue_amount_usd) AS total_revenue,
       COUNT(DISTINCT user_id) AS unique_users,
       ROUND(SUM(revenue_amount_usd) / COUNT(DISTINCT user_id), 2) AS arpu,
       ROUND(SUM(revenue_amount_usd) / COUNT(*), 2) AS rps,
       ROUND(AVG(session_duration_minutes), 2) AS avg_session_duration
FROM game_payments_cleaned
GROUP BY game_name
ORDER BY total_revenue DESC;

-- 🔹 Platform Analysis:
-- Revenue and session length by platform and region.
SELECT platform,
       country_cleaned,
       SUM(revenue_amount_usd) AS total_revenue,
       ROUND(AVG(session_duration_minutes), 2) AS avg_session_duration,
       COUNT(DISTINCT user_id) AS users
FROM game_payments_cleaned
GROUP BY platform, country_cleaned
ORDER BY total_revenue DESC;

-- Revenue, ARPU and average engagement by platform.
SELECT 
      platform,
      COUNT(DISTINCT user_id) AS unique_users,
      SUM(session_duration_minutes) AS total_play_time,
      SUM(revenue_amount_usd) AS total_revenue,
      SUM(revenue_amount_usd) / COUNT(DISTINCT user_id) AS arpu,
      SUM(session_duration_minutes) / COUNT(DISTINCT user_id) AS avg_play_time_per_user
FROM game_payments_cleaned
GROUP BY platform
ORDER BY total_revenue DESC;

-- 🔹 Regional Insights:
-- Total revenue, revenue per user, and engagement across countries.
SELECT country_cleaned,
       SUM(revenue_amount_usd) AS total_revenue,
       ROUND(SUM(revenue_amount_usd) / COUNT(DISTINCT user_id), 2) AS revenue_per_user,
       ROUND(AVG(session_duration_minutes), 2) AS avg_session_duration
FROM game_payments_cleaned
GROUP BY country_cleaned
ORDER BY total_revenue DESC;

-- Top cities by revenue.
SELECT 
      city,
      country_cleaned AS country,
      SUM(revenue_amount_usd) AS total_revenue
FROM game_payments_cleaned
GROUP BY city, country_cleaned
ORDER BY total_revenue DESC
LIMIT 10;

-- 🔹 Revenue trends over time:
-- Revenue by month, week and day.
SELECT DATE_TRUNC('month', payment_date) AS month, SUM(revenue_amount_usd) AS revenue
FROM game_payments_cleaned
GROUP BY month ORDER BY month;

SELECT DATE_TRUNC('week', payment_date) AS week, SUM(revenue_amount_usd) AS revenue
FROM game_payments_cleaned
GROUP BY week ORDER BY week;

SELECT payment_date::date AS day, SUM(revenue_amount_usd) AS revenue
FROM game_payments_cleaned
GROUP BY day ORDER BY day;

-- 🔹 Payment Frequency:
-- Frequency and average time between payments.
SELECT user_id, COUNT(*) AS payment_count, MIN(payment_date) AS first_payment, MAX(payment_date) AS last_payment,
       MAX(payment_date) - MIN(payment_date) AS active_days
FROM game_payments_cleaned
GROUP BY user_id
ORDER BY payment_count DESC;

WITH user_intervals AS (
    SELECT user_id, payment_date,
           LAG(payment_date) OVER (PARTITION BY user_id ORDER BY payment_date) AS prev_payment
    FROM game_payments_cleaned
)
SELECT ROUND(AVG(payment_date - prev_payment), 2) AS avg_days_between_payments
FROM user_intervals
WHERE prev_payment IS NOT NULL;

-- 🔹 Metrics: LTV, RPU, RPS
-- Efficiency of revenue generation per session and per user.
SELECT user_id,
       SUM(revenue_amount_usd) AS ltv,
       MIN(payment_date) AS first_payment,
       MAX(payment_date) AS last_payment,
       DATE_PART('day', MAX(payment_date) - MIN(payment_date)) AS active_days
FROM game_payments_cleaned
GROUP BY user_id;

-- Rpu, rps.
SELECT ROUND(SUM(revenue_amount_usd) / COUNT(DISTINCT user_id), 2) AS rpu,
       ROUND(SUM(revenue_amount_usd) / COUNT(*), 2) AS rps
FROM game_payments_cleaned;

-- 🔹 Retention Indicators:
-- Users who returned in the following month.
WITH user_months AS (
  SELECT 
        user_id,
        DATE_TRUNC('month', payment_date) AS payment_month
  FROM game_payments_cleaned
  GROUP BY user_id, DATE_TRUNC('month', payment_date)
),
month_pairs AS (
  SELECT 
        user_id,
        payment_month,
        LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) AS next_month
  FROM user_months
)
SELECT 
      COUNT(*) AS retained_users
FROM month_pairs
WHERE next_month = payment_month + INTERVAL '1 month';

-- Monthly user retention since first payment.
WITH first_payment_month AS (
  SELECT user_id, MIN(DATE_TRUNC('month', payment_date)) AS cohort_month
  FROM game_payments_cleaned
  GROUP BY user_id
),
user_months AS (
  SELECT g.user_id, f.cohort_month, DATE_TRUNC('month', g.payment_date) AS active_month
  FROM game_payments_cleaned g
  JOIN first_payment_month f ON g.user_id = f.user_id
),
cohort_analysis AS (
  SELECT cohort_month,
         (DATE_PART('year', age(active_month, cohort_month)) * 12 +
          DATE_PART('month', age(active_month, cohort_month))) AS months_since_signup,
         COUNT(DISTINCT user_id) AS active_users
  FROM user_months
  GROUP BY cohort_month, months_since_signup
)
SELECT * FROM cohort_analysis
ORDER BY cohort_month, months_since_signup;
