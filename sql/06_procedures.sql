USE car_sales;

DROP PROCEDURE IF EXISTS sp_create_sales_order;
DELIMITER $$
CREATE PROCEDURE sp_create_sales_order(
    IN p_customer_id INT,
    IN p_sales_consultant_id INT,
    IN p_vin CHAR(17),
    IN p_vehicle_amount DECIMAL(12,2),
    IN p_option_amount DECIMAL(12,2),
    IN p_insurance_amount DECIMAL(12,2),
    IN p_discount_amount DECIMAL(12,2),
    IN p_deposit_amount DECIMAL(12,2),
    IN p_payment_method VARCHAR(20)
)
BEGIN
    DECLARE v_order_no VARCHAR(32);
    DECLARE v_vehicle_status VARCHAR(20);
    DECLARE v_total_amount DECIMAL(12,2);

    SET v_total_amount = p_vehicle_amount + p_option_amount + p_insurance_amount - p_discount_amount;

    IF v_total_amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '订单总金额不能为负数';
    END IF;

    START TRANSACTION;

    SELECT status INTO v_vehicle_status
    FROM inventory_vehicles
    WHERE vin = p_vin
    FOR UPDATE;

    IF v_vehicle_status IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '创建订单失败：车辆不存在';
    END IF;

    IF v_vehicle_status <> '在库' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '创建订单失败：车辆不是在库状态';
    END IF;

    SET v_order_no = CONCAT('SO', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), LPAD(FLOOR(RAND() * 1000), 3, '0'));

    INSERT INTO sales_orders (
        order_no, customer_id, sales_consultant_id, vin,
        total_amount, deposit_amount, order_status, payment_method, created_at
    ) VALUES (
        v_order_no, p_customer_id, p_sales_consultant_id, p_vin,
        v_total_amount, p_deposit_amount,
        CASE WHEN p_deposit_amount > 0 THEN '待交付' ELSE '待定金' END,
        p_payment_method,
        NOW()
    );

    INSERT INTO sales_order_items (order_no, item_type, item_desc, amount)
    VALUES (v_order_no, '车辆', '车辆成交价', p_vehicle_amount);

    IF p_option_amount > 0 THEN
        INSERT INTO sales_order_items (order_no, item_type, item_desc, amount)
        VALUES (v_order_no, '选装', '选装配件', p_option_amount);
    END IF;

    IF p_insurance_amount > 0 THEN
        INSERT INTO sales_order_items (order_no, item_type, item_desc, amount)
        VALUES (v_order_no, '保险', '保险套餐', p_insurance_amount);
    END IF;

    IF p_discount_amount > 0 THEN
        INSERT INTO sales_order_items (order_no, item_type, item_desc, amount)
        VALUES (v_order_no, '其他', '折扣优惠', -p_discount_amount);
    END IF;

    COMMIT;

    SELECT v_order_no AS new_order_no, v_total_amount AS total_amount;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_get_monthly_report;
DELIMITER $$
CREATE PROCEDURE sp_get_monthly_report(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    SELECT
        p_year AS report_year,
        p_month AS report_month,
        COUNT(*) AS total_orders,
        SUM(so.total_amount) AS total_sales_amount,
        SUM(so.total_amount - iv.procurement_cost) AS total_gross_profit,
        AVG(so.total_amount) AS avg_order_amount
    FROM sales_orders so
    JOIN inventory_vehicles iv ON so.vin = iv.vin
    WHERE so.order_status = '已完成'
      AND YEAR(so.created_at) = p_year
      AND MONTH(so.created_at) = p_month;
END$$
DELIMITER ;
