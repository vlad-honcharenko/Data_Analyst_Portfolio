-- 1. Monthly user churn rate.
WITH monthly_activity AS (
	SELECT 
		DISTINCT date_trunc('month', payment_date) AS month,
		user_id
	FROM game_payments_cleaned
),
churn_count_users AS ( 
SELECT
	CAST(current_month.month + interval '1 month' AS date) AS month, 
	SUM(CASE WHEN next_month.month IS NULL THEN 1 ElSE 0 END) AS churned_users
FROM monthly_activity current_month
	LEFT JOIN monthly_activity next_month
	ON current_month.month + interval '1 month' = next_month.month
	AND current_month.user_id = next_month.user_id
GROUP BY 1
ORDER BY 1
)
SELECT
	ma.month::date,
	COUNT(DISTINCT ma.user_id) AS paid_users,
	cu.churned_users,
	ROUND(cu.churned_users * 1.00 / COUNT(DISTINCT ma.user_id) * 100.00, 2) AS churne_rate
FROM monthly_activity ma
	LEFT JOIN churn_count_users cu
	ON ma.month = cu.month
GROUP BY 1,3
;

-- 2. ARPPU by month.
SELECT 
	payment_month,
	round(SUM(monthly_revenue) / COUNT(DISTINCT user_id),2) AS arppu
FROM (
	SELECT 
		user_id,
		(DATE_TRUNC('month', payment_date))::date AS payment_month,
		(SUM(revenue_amount_usd)) AS monthly_revenue
	FROM game_payments_cleaned
	GROUP BY 1,2
	ORDER BY 1,2
	) AS monthly_payments
GROUP BY 1
ORDER BY 1
;

-- 3. New paying users per month.
SELECT
	CAST(first_payment_month AS date),
	COUNT(DISTINCT user_id) AS new_paid_users
FROM (
    SELECT 
        user_id,
        MIN(DATE_TRUNC('month', payment_date)) AS first_payment_month
    FROM game_payments_cleaned
    GROUP BY 1) AS first_payment_per_user
GROUP BY 1
;

-- 4. Revenue churn rate.
WITH user_payments AS (
    SELECT 
        user_id,
        DATE_TRUNC('month', payment_date) AS payment_month,
        SUM(revenue_amount_usd) AS monthly_revenue
    FROM game_payments_cleaned
    GROUP BY 1,2
    ORDER BY 1,2
),
payment_months AS (
    SELECT
        user_id,
        monthly_revenue,
        payment_month,
        LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) AS next_payment_month
    FROM user_payments
),
churned_revenue AS(
  	SELECT 
  	    (payment_month + INTERVAL '1 month')::date AS month,
    		ROUND(SUM(monthly_revenue),0) AS churned_revenue
  	FROM payment_months
  	WHERE next_payment_month IS NULL OR next_payment_month > payment_month + INTERVAL '1 month'
  	GROUP BY 1
  	ORDER BY 1
),
mrr AS(
  	SELECT 
  		(payment_month)::date AS month,
  		ROUND(SUM(monthly_revenue),0) AS MRR
  	FROM payment_months
  	GROUP BY 1
  	ORDER BY 1
),
previous_month_mrr AS (
    SELECT 
        (MONTH + INTERVAL '1 month')::date AS month,
        mrr AS previous_mrr
    FROM mrr
)
SELECT
    mrr.month,
    cr.churned_revenue,
    mrr.mrr,
    ROUND(COALESCE(cr.churned_revenue*1.00 / NULLIF(pm.previous_mrr, 0)*100.00, 0),2) AS revenue_churn_rate
FROM mrr
  LEFT JOIN churned_revenue cr 
    ON mrr.month = cr.month 
  LEFT JOIN previous_month_mrr pm 
    ON mrr.month = pm.month
ORDER BY mrr.month
;

-- 5. MRR.
WITH user_payments AS (
    SELECT 
        user_id,
        DATE_TRUNC('month', payment_date) AS payment_month,
        SUM(revenue_amount_usd) AS monthly_revenue
    FROM game_payments_cleaned
    GROUP BY 1,2
    ORDER BY 1,2
),
payment_months AS (
    SELECT
        user_id,
        monthly_revenue,
        payment_month,
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY payment_month) AS num_payment_month
    FROM user_payments
)
SELECT
	(payment_month)::date AS month,
	ROUND(SUM(monthly_revenue),0) AS new_mrr
FROM payment_months
WHERE num_payment_month = '1'
GROUP BY 1
ORDER BY 1
;

-- 6. Expansion vs. Contraction MRR.
WITH user_payments AS (
    SELECT
        user_id,
        CAST(DATE_TRUNC('month', payment_date) AS date) AS month,
        SUM(revenue_amount_usd) AS mrr
    FROM game_payments_cleaned
    GROUP BY 1,2
    ORDER BY 1,2
),
previous_month_payment AS (
    SELECT
    	  user_id,
        (month + INTERVAL '1 month')::date AS month,
        mrr AS previous_mrr
    FROM user_payments
),
expansion_mrr AS(
  	SELECT 
    		mrr.month,
    		SUM(mrr.mrr - pmrr.previous_mrr) AS expansion_mrr
  	FROM user_payments mrr
  		LEFT JOIN previous_month_payment pmrr
  			ON mrr.user_id = pmrr.user_id 
          AND mrr.month = pmrr.month
  	WHERE mrr.mrr > pmrr.previous_mrr
  	GROUP BY 1
  	ORDER BY 1
),
contraction_mrr AS (
  	SELECT
    		mrr.month,
    		SUM(mrr.mrr - pmrr.previous_mrr) AS contraction_mrr
  	FROM user_payments mrr
  		LEFT JOIN previous_month_payment pmrr
  			ON mrr.user_id = pmrr.user_id 
          AND mrr.month = pmrr.month
  	WHERE mrr.mrr < pmrr.previous_mrr
  	GROUP BY 1
  	ORDER BY 1
)
SELECT 
  	emrr.month,
  	emrr.expansion_mrr,
  	cmrr.contraction_mrr
FROM expansion_mrr emrr
  LEFT JOIN contraction_mrr cmrr
    ON emrr.month = cmrr.month
;

-- 7. Average customer lifetime.
SELECT 
	ROUND(AVG(payment_month), 2) AS life_time
FROM (
	SELECT 
		user_id,
		COUNT(DISTINCT DATE_TRUNC('month', payment_date)) AS payment_month
	FROM game_payments_cleaned
	GROUP BY 1
	) AS months_count
;
