WITH engagement_dates AS (
  SELECT
  DISTINCT user_id,
  LAG(DATE_TRUNC('day', e.engagement_date), 1) OVER (PARTITION BY user_id ORDER BY date_created) AS previous_engagement_date,
  DATE_TRUNC('day', MAX(e.engagement_date)) AS max_engagement_date
  FROM (
    SELECT 
    DISTINCT user_id, 
    engagement_date
    FROM events
    GROUP BY user_id, date_created
  ) e
  GROUP BY user_id
),
retention_buckets AS (
  SELECT 
  user_id,
  CASE
    WHEN previous_engagement_date is NULL THEN 'nurr'
    WHEN max_engagement_date = CURRENT_DATE AND previous_engagement_date BETWEEN CURRENT_DATE - 6 AND CURRENT_DATE THEN 'curr'
    WHEN max_engagement_date = CURRENT_DATE AND previous_engagement_date BETWEEN CURRENT_DATE - 29 AND CURRENT_DATE - 7 THEN 'rurr'
    WHEN max_engagement_date = CURRENT_DATE AND previous_engagement_date < CURRENT_DATE - 30 THEN 'surr'
    WHEN max_engagement_date BETWEEN (CURRENT_DATE) - 7) AND (CURRENT_DATE) - 1) THEN 'risk_wau'
    WHEN max_engagement_date BETWEEN (CURRENT_DATE) - 30) AND (CURRENT_DATE) - 8) THEN 'risk_mau'
    WHEN max_engagement_date < (CURRENT_DATE) - 30 THEN 'dormant'
    ELSE 'unknown'
  END AS bucket
  FROM engagement_dates
),
metrics AS (
  SELECT 
  bucket,
  SUM(CASE WHEN bucket in ('nurr', 'curr', 'rurr', 'surr') THEN 1 ELSE 0 END) AS dau,
  COUNT(DISTINCT user_id) AS user_count
  FROM retention_buckets
  GROUP BY bucket
)

SELECT
SUM(CASE WHEN bucket = 'nurr' THEN user_count ELSE 0 END) AS nurr,
SUM(CASE WHEN bucket = 'curr' THEN user_count ELSE 0 END) AS curr,
SUM(CASE WHEN bucket = 'rurr' THEN user_count ELSE 0 END) AS rurr,
SUM(CASE WHEN bucket = 'surr' THEN user_count ELSE 0 END) AS surr,
dau AS dau,
SUM(CASE WHEN bucket = 'risk_wau' THEN user_count ELSE 0 END) AS risk_wau,
SUM(CASE WHEN bucket = 'risk_wau' THEN user_count ELSE 0 END) + dau AS wau,
SUM(CASE WHEN bucket = 'risk_mau' THEN user_count ELSE 0 END) AS risk_mau,
(
  SUM(CASE WHEN bucket = 'risk_mau' THEN user_count ELSE 0 END)
  + SUM(CASE WHEN bucket = 'risk_wau' THEN user_count ELSE 0 END)
  + dau
) AS mau,
SUM(CASE WHEN bucket = 'dormant' THEN user_count ELSE 0 END) AS dormant,
SUM(CASE WHEN bucket = 'unknown' THEN user_count ELSE 0 END) AS unknown,
SUM(user_count) AS total_users
FROM metrics