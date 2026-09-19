-- View: أداء العروض لكل مورد
CREATE OR REPLACE VIEW vendor_offer_performance AS
SELECT
    o.vendor_id,
    o.id AS offer_id,
    o.title,
    o.total_quantity,
    o.sold_quantity,
    ROUND((o.sold_quantity::NUMERIC / NULLIF(o.total_quantity, 0)) * 100, 1) AS sell_through_pct,
    o.offer_price * o.sold_quantity AS total_revenue,
    o.created_at
FROM offers o
WHERE o.is_active = TRUE OR o.sold_quantity > 0;

-- View: أكثر الأصناف مبيعاً لكل مورد
CREATE OR REPLACE VIEW vendor_top_products AS
SELECT
    so.vendor_id,
    soi.product_id,
    soi.product_name,
    SUM(soi.quantity) AS total_quantity_sold,
    SUM(soi.total_price) AS total_revenue,
    COUNT(DISTINCT so.id) AS orders_count
FROM sub_order_items soi
JOIN sub_orders so ON so.id = soi.sub_order_id
WHERE so.status IN ('delivered', 'shipped', 'processing')
GROUP BY so.vendor_id, soi.product_id, soi.product_name
ORDER BY total_quantity_sold DESC;

-- View: إحصائيات المورد العامة
CREATE OR REPLACE VIEW vendor_stats AS
SELECT
    so.vendor_id,
    COUNT(DISTINCT so.id) AS total_orders,
    COUNT(DISTINCT CASE WHEN so.status = 'pending' THEN so.id END) AS pending_orders,
    COUNT(DISTINCT CASE WHEN so.status = 'delivered' THEN so.id END) AS delivered_orders,
    COALESCE(SUM(CASE WHEN so.status IN ('delivered','shipped','processing') THEN so.subtotal END), 0) AS total_revenue,
    COALESCE(AVG(CASE WHEN so.status IN ('delivered','shipped') THEN so.subtotal END), 0) AS avg_order_value
FROM sub_orders so
GROUP BY so.vendor_id;

-- View: أداء الموردين الشهري (للأدمن)
CREATE OR REPLACE VIEW monthly_vendor_performance AS
SELECT
    v.id AS vendor_id,
    v.store_name,
    DATE_TRUNC('month', so.created_at) AS month,
    COUNT(so.id) AS orders_count,
    SUM(so.subtotal) AS revenue
FROM vendors v
LEFT JOIN sub_orders so ON so.vendor_id = v.id
WHERE so.status IN ('delivered', 'shipped')
GROUP BY v.id, v.store_name, DATE_TRUNC('month', so.created_at)
ORDER BY month DESC;