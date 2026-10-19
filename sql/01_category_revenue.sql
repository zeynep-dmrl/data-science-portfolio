-- Top 10 product categories by revenue (cancelled and returned items excluded)
SELECT
  products.category,
  ROUND(SUM(orderItems.sale_price), 2) AS revenue
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS orderItems
INNER JOIN `bigquery-public-data.thelook_ecommerce.products` AS products
  ON orderItems.product_id = products.id
WHERE orderItems.status NOT IN ('Cancelled', 'Returned')
GROUP BY products.category
ORDER BY revenue DESC
LIMIT 10;
