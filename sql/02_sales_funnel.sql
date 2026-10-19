-- Overall sales funnel: product view -> add to cart -> purchase (distinct sessions)
WITH funnel AS (
  SELECT
    COUNT(DISTINCT IF(event_type = 'product',  session_id, NULL)) AS product_views,
    COUNT(DISTINCT IF(event_type = 'cart',     session_id, NULL)) AS add_to_cart,
    COUNT(DISTINCT IF(event_type = 'purchase', session_id, NULL)) AS purchases
  FROM `bigquery-public-data.thelook_ecommerce.events`
)
SELECT
  *,
  ROUND(100 * SAFE_DIVIDE(add_to_cart, product_views), 1) AS view_to_cart_pct,
  ROUND(100 * SAFE_DIVIDE(purchases, add_to_cart), 1)     AS cart_to_purchase_pct
FROM funnel;
