USE car_sales;

-- Q1: 查询指定时间段（示例：2026年第一季度）的总订单数、总销售额、总毛利
SELECT
    COUNT(*) AS total_orders,
    SUM(so.total_amount) AS total_sales_amount,
    SUM(so.total_amount - iv.procurement_cost) AS total_gross_profit
FROM sales_orders so
JOIN inventory_vehicles iv ON so.vin = iv.vin
WHERE so.order_status = '已完成'
  AND so.created_at >= '2026-01-01'
  AND so.created_at < '2026-04-01';

-- Q2: 查询每位销售顾问的月度/季度业绩并排名
SELECT
    t.period_type,
    t.period_value,
    t.employee_id,
    t.employee_name,
    t.order_count,
    t.sales_amount,
    t.gross_profit,
    DENSE_RANK() OVER (PARTITION BY t.period_type, t.period_value ORDER BY t.sales_amount DESC) AS sales_rank
FROM (
    SELECT
        'MONTH' AS period_type,
        DATE_FORMAT(so.created_at, '%Y-%m') AS period_value,
        e.employee_id,
        e.employee_name,
        COUNT(*) AS order_count,
        SUM(so.total_amount) AS sales_amount,
        SUM(so.total_amount - iv.procurement_cost) AS gross_profit
    FROM sales_orders so
    JOIN employees e ON so.sales_consultant_id = e.employee_id
    JOIN inventory_vehicles iv ON so.vin = iv.vin
    WHERE so.order_status = '已完成'
    GROUP BY DATE_FORMAT(so.created_at, '%Y-%m'), e.employee_id, e.employee_name

    UNION ALL

    SELECT
        'QUARTER' AS period_type,
        CONCAT(YEAR(so.created_at), '-Q', QUARTER(so.created_at)) AS period_value,
        e.employee_id,
        e.employee_name,
        COUNT(*) AS order_count,
        SUM(so.total_amount) AS sales_amount,
        SUM(so.total_amount - iv.procurement_cost) AS gross_profit
    FROM sales_orders so
    JOIN employees e ON so.sales_consultant_id = e.employee_id
    JOIN inventory_vehicles iv ON so.vin = iv.vin
    WHERE so.order_status = '已完成'
    GROUP BY CONCAT(YEAR(so.created_at), '-Q', QUARTER(so.created_at)), e.employee_id, e.employee_name
) t
ORDER BY t.period_type, t.period_value, sales_rank;

-- Q3: 查询最畅销车型Top5及销量
SELECT
    b.brand_name,
    m.series_name,
    m.model_year,
    m.trim_name,
    COUNT(*) AS sold_count
FROM sales_orders so
JOIN inventory_vehicles v ON so.vin = v.vin
JOIN car_models m ON v.model_id = m.model_id
JOIN brands b ON m.brand_id = b.brand_id
WHERE so.order_status = '已完成'
GROUP BY b.brand_name, m.series_name, m.model_year, m.trim_name
ORDER BY sold_count DESC
LIMIT 5;

-- Q4: 查询库存周期超过90天的滞销车辆
SELECT
    v.vin,
    b.brand_name,
    m.series_name,
    m.trim_name,
    v.inbound_date,
    v.sold_at,
    DATEDIFF(v.sold_at, v.inbound_date) AS inventory_days
FROM inventory_vehicles v
JOIN car_models m ON v.model_id = m.model_id
JOIN brands b ON m.brand_id = b.brand_id
WHERE v.status = '已售出'
  AND v.inbound_date IS NOT NULL
  AND v.sold_at IS NOT NULL
  AND DATEDIFF(v.sold_at, v.inbound_date) > 90
ORDER BY inventory_days DESC;

-- Q5: 根据客户历史消费总额进行分层
SELECT
    c.customer_id,
    c.customer_name,
    c.phone,
    COALESCE(SUM(CASE WHEN so.order_status = '已完成' THEN so.total_amount END), 0) AS total_consumption,
    CASE
        WHEN COALESCE(SUM(CASE WHEN so.order_status = '已完成' THEN so.total_amount END), 0) < 100000 THEN '普通客户'
        WHEN COALESCE(SUM(CASE WHEN so.order_status = '已完成' THEN so.total_amount END), 0) < 300000 THEN '银卡客户'
        ELSE '金卡客户'
    END AS customer_level
FROM customers c
LEFT JOIN sales_orders so ON c.customer_id = so.customer_id
GROUP BY c.customer_id, c.customer_name, c.phone
ORDER BY total_consumption DESC;

-- Q6: 查询特定客户的完整购车及售后历史（示例 customer_id=1）
SELECT
    '购车' AS record_type,
    so.order_no AS record_no,
    so.created_at AS record_time,
    so.order_status AS status,
    so.total_amount AS amount,
    CONCAT(b.brand_name, '-', m.series_name, '-', m.trim_name) AS detail
FROM sales_orders so
JOIN inventory_vehicles v ON so.vin = v.vin
JOIN car_models m ON v.model_id = m.model_id
JOIN brands b ON m.brand_id = b.brand_id
WHERE so.customer_id = 1
UNION ALL
SELECT
    '售后' AS record_type,
    sv.service_order_no AS record_no,
    sv.created_at AS record_time,
    sv.status,
    sv.total_fee AS amount,
    CONCAT(sv.service_type, '服务') AS detail
FROM service_orders sv
WHERE sv.customer_id = 1
ORDER BY record_time;

-- Q7: 库存预警报表（在库数量低于安全库存阈值）
SELECT
    b.brand_name,
    m.series_name,
    m.model_year,
    m.trim_name,
    m.safety_stock,
    COALESCE(SUM(CASE WHEN v.status = '在库' THEN 1 ELSE 0 END), 0) AS in_stock_count
FROM car_models m
JOIN brands b ON m.brand_id = b.brand_id
LEFT JOIN inventory_vehicles v ON m.model_id = v.model_id
GROUP BY b.brand_name, m.series_name, m.model_year, m.trim_name, m.safety_stock
HAVING in_stock_count < m.safety_stock
ORDER BY (m.safety_stock - in_stock_count) DESC;

-- Q8: 自定义业务查询：统计不同客户来源渠道的成交转化率
SELECT
    c.source_channel,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT CASE WHEN so.order_status = '已完成' THEN c.customer_id END) AS converted_customer_count,
    ROUND(
        COUNT(DISTINCT CASE WHEN so.order_status = '已完成' THEN c.customer_id END)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0) * 100,
        2
    ) AS conversion_rate_pct
FROM customers c
LEFT JOIN sales_orders so ON c.customer_id = so.customer_id
GROUP BY c.source_channel
ORDER BY conversion_rate_pct DESC;
