-- 1. نظرة عامة يومية
CREATE OR REPLACE VIEW admin_daily_overview AS
SELECT
    DATE(o.created_at) AS day,
    COUNT(DISTINCT o.id) AS orders_count,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    COALESCE(SUM(o.total_amount), 0) AS revenue,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
    COUNT(DISTINCT so.vendor_id) AS active_vendors
FROM orders o
LEFT JOIN sub_orders so ON so.order_id = o.id
WHERE o.created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(o.created_at)
ORDER BY day DESC;

-- 2. أداء الموردين (Leaderboard)
CREATE OR REPLACE VIEW admin_vendor_leaderboard AS
SELECT
    v.id AS vendor_id,
    v.store_name,
    v.logo_url,
    COUNT(DISTINCT so.id) AS total_orders,
    COALESCE(SUM(so.subtotal), 0) AS total_revenue,
    COALESCE(AVG(so.subtotal), 0) AS avg_order_value,
    ROUND(
        COUNT(CASE WHEN so.status = 'delivered' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(so.id), 0) * 100, 1
    ) AS fulfillment_rate,
    ROUND(
        COUNT(CASE WHEN so.status = 'rejected' THEN 1 END)::NUMERIC /
        NULLIF(COUNT(so.id), 0) * 100, 1
    ) AS rejection_rate
FROM vendors v
LEFT JOIN sub_orders so ON so.vendor_id = v.id
WHERE v.is_approved = TRUE
GROUP BY v.id, v.store_name, v.logo_url
ORDER BY total_revenue DESC;

-- 3. أكثر التصنيفات مبيعاً
CREATE OR REPLACE VIEW admin_category_performance AS
SELECT
    c.id AS category_id,
    c.name_ar,
    c.name_en,
    COUNT(DISTINCT soi.id) AS items_sold,
    COALESCE(SUM(soi.total_price), 0) AS revenue
FROM categories c
LEFT JOIN products p ON p.category_id = c.id
LEFT JOIN sub_order_items soi ON soi.product_id = p.id
LEFT JOIN sub_orders so ON so.id = soi.sub_order_id
WHERE so.status IN ('delivered', 'shipped', 'processing')
GROUP BY c.id, c.name_ar, c.name_en
ORDER BY revenue DESC;

-- 4. معدل تحويل العروض
CREATE OR REPLACE VIEW admin_offer_conversion AS
SELECT
    o.id AS offer_id,
    o.title,
    o.vendor_id,
    v.store_name,
    o.total_quantity,
    o.sold_quantity,
    ROUND(o.sold_quantity::NUMERIC / NULLIF(o.total_quantity, 0) * 100, 1) AS conversion_pct,
    o.offer_price * o.sold_quantity AS revenue,
    o.created_at
FROM offers o
JOIN vendors v ON v.id = o.vendor_id
ORDER BY conversion_pct DESC;

-- 5. معدل العملاء النشطين (retention)
CREATE OR REPLACE VIEW admin_customer_retention AS
WITH first_orders AS (
    SELECT customer_id, MIN(created_at) AS first_order_date
    FROM orders
    GROUP BY customer_id
),
recurring AS (
    SELECT
        o.customer_id,
        DATE_TRUNC('month', o.created_at) AS month,
        COUNT(*) AS orders_count
    FROM orders o
    GROUP BY o.customer_id, DATE_TRUNC('month', o.created_at)
)
SELECT
    DATE_TRUNC('month', fo.first_order_date)::DATE AS cohort_month,
    COUNT(DISTINCT fo.customer_id) AS cohort_size,
    COUNT(DISTINCT r.customer_id) FILTER (WHERE r.month > DATE_TRUNC('month', fo.first_order_date)) AS returned,
    ROUND(
        COUNT(DISTINCT r.customer_id) FILTER (WHERE r.month > DATE_TRUNC('month', fo.first_order_date))::NUMERIC /
        NULLIF(COUNT(DISTINCT fo.customer_id), 0) * 100, 1
    ) AS retention_pct
FROM first_orders fo
LEFT JOIN recurring r ON r.customer_id = fo.customer_id
GROUP BY DATE_TRUNC('month', fo.first_order_date)
ORDER BY cohort_month DESC;