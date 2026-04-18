USE car_sales;

DROP VIEW IF EXISTS v_sales_performance;
CREATE VIEW v_sales_performance AS
SELECT
    e.employee_id,
    e.employee_name,
    DATE_FORMAT(so.created_at, '%Y-%m') AS stat_month,
    CONCAT(YEAR(so.created_at), '-Q', QUARTER(so.created_at)) AS stat_quarter,
    COUNT(CASE WHEN so.order_status <> '已取消' THEN 1 END) AS order_count,
    COALESCE(SUM(CASE WHEN so.order_status <> '已取消' THEN so.total_amount END), 0) AS sales_amount,
    COALESCE(SUM(
        CASE
            WHEN so.order_status <> '已取消' THEN so.total_amount - iv.procurement_cost
            ELSE 0
        END
    ), 0) AS gross_profit
FROM employees e
LEFT JOIN sales_orders so ON e.employee_id = so.sales_consultant_id
LEFT JOIN inventory_vehicles iv ON so.vin = iv.vin
WHERE e.role_name = '销售顾问'
GROUP BY e.employee_id, e.employee_name, DATE_FORMAT(so.created_at, '%Y-%m'), CONCAT(YEAR(so.created_at), '-Q', QUARTER(so.created_at));

DROP VIEW IF EXISTS v_inventory_summary;
CREATE VIEW v_inventory_summary AS
SELECT
    m.model_id,
    b.brand_name,
    m.series_name,
    m.model_year,
    m.trim_name,
    m.safety_stock,
    SUM(CASE WHEN v.status = '在库' THEN 1 ELSE 0 END) AS in_stock_count,
    SUM(CASE WHEN v.status = '已锁定' THEN 1 ELSE 0 END) AS locked_count,
    SUM(CASE WHEN v.status = '在途' THEN 1 ELSE 0 END) AS in_transit_count,
    SUM(CASE WHEN v.status = '已售出' THEN 1 ELSE 0 END) AS sold_count
FROM car_models m
JOIN brands b ON m.brand_id = b.brand_id
LEFT JOIN inventory_vehicles v ON m.model_id = v.model_id
GROUP BY m.model_id, b.brand_name, m.series_name, m.model_year, m.trim_name, m.safety_stock;

DROP VIEW IF EXISTS v_customer_value;
CREATE VIEW v_customer_value AS
SELECT
    c.customer_id,
    c.customer_name,
    c.phone,
    COUNT(CASE WHEN so.order_status = '已完成' THEN 1 END) AS completed_order_count,
    COALESCE(SUM(CASE WHEN so.order_status = '已完成' THEN so.total_amount END), 0) AS total_consumption,
    CASE
        WHEN COALESCE(SUM(CASE WHEN so.order_status = '已完成' THEN so.total_amount END), 0) < 100000 THEN '普通客户'
        WHEN COALESCE(SUM(CASE WHEN so.order_status = '已完成' THEN so.total_amount END), 0) < 300000 THEN '银卡客户'
        ELSE '金卡客户'
    END AS customer_level
FROM customers c
LEFT JOIN sales_orders so ON c.customer_id = so.customer_id
GROUP BY c.customer_id, c.customer_name, c.phone;
