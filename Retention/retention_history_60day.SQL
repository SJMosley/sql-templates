--The current data isn't good enough to support this query. All nurr users are going to be from the day you generated the users.
WITH date_series AS (
  SELECT generate_series(
    CURRENT_DATE - INTERVAL '59 days',
    CURRENT_DATE,
    INTERVAL '1 day'
  )::date AS date
),
engagement_dates AS (
  SELECT DISTINCT ON (user_id)
  	report_date,
	user_id,
	LAG(DATE_TRUNC('day', engagement_date), 1) OVER (PARTITION BY user_id ORDER BY engagement_date) AS previous_engagement_date,
	MAX(DATE_TRUNC('day', engagement_date)) OVER (PARTITION BY user_id) AS max_engagement_date
	FROM (
	  SELECT 
		ds.date AS report_date,
	    e.user_id, 
	    e.date_created AS engagement_date
	  FROM events e
	  JOIN date_series ds ON e.date_created <= ds.date
		) e
	ORDER BY user_id, engagement_date DESC
),
retention_buckets AS (
  SELECT
  report_date,
  user_id,
  CASE
    WHEN previous_engagement_date is NULL THEN 'nurr'
    WHEN max_engagement_date = report_date AND previous_engagement_date BETWEEN report_date - 6 AND CURRENT_DATE THEN 'curr'
    WHEN max_engagement_date = report_date AND previous_engagement_date BETWEEN report_date - 29 AND CURRENT_DATE - 7 THEN 'rurr'
    WHEN max_engagement_date = report_date AND previous_engagement_date < report_date - 30 THEN 'surr'
    WHEN max_engagement_date BETWEEN report_date - 7 AND report_date - 1 THEN 'risk_wau'
    WHEN max_engagement_date BETWEEN report_date - 30 AND report_date - 8 THEN 'risk_mau'
    WHEN max_engagement_date < report_date - 30 THEN 'dormant'
    ELSE 'unknown'
  END AS bucket
  FROM engagement_dates
),
metrics AS (
  SELECT
  report_date,
  bucket,
  COUNT(DISTINCT user_id) AS user_count
  FROM retention_buckets
  GROUP BY report_date, bucket
),
dau AS (
	SELECT
	report_date, 
	SUM(CASE WHEN bucket in ('nurr', 'curr', 'rurr', 'surr') THEN 1 ELSE 0 END) AS dau
	FROM retention_buckets
	GROUP BY report_date
)

	SELECT DISTINCT ON (report_date)
	metrics.report_date,
	SUM(CASE WHEN bucket = 'nurr' THEN user_count ELSE 0 END) AS nurr,
	SUM(CASE WHEN bucket = 'curr' THEN user_count ELSE 0 END) AS curr,
	SUM(CASE WHEN bucket = 'rurr' THEN user_count ELSE 0 END) AS rurr,
	SUM(CASE WHEN bucket = 'surr' THEN user_count ELSE 0 END) AS surr,
	dau.dau AS dau,
	SUM(CASE WHEN bucket = 'risk_wau' THEN user_count ELSE 0 END) AS risk_wau,
	SUM(CASE WHEN bucket = 'risk_wau' THEN user_count ELSE 0 END) + dau.dau AS wau,
	SUM(CASE WHEN bucket = 'risk_mau' THEN user_count ELSE 0 END) AS risk_mau,
	(
	  SUM(CASE WHEN bucket = 'risk_mau' THEN user_count ELSE 0 END)
	  + SUM(CASE WHEN bucket = 'risk_wau' THEN user_count ELSE 0 END)
	  + dau.dau
	) AS mau,
	SUM(CASE WHEN bucket = 'dormant' THEN user_count ELSE 0 END) AS dormant,
	SUM(CASE WHEN bucket = 'unknown' THEN user_count ELSE 0 END) AS unknown,
	SUM(user_count) AS total_users
	FROM metrics, dau
	GROUP BY metrics.report_date, dau.dau
;