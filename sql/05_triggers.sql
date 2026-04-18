USE car_sales;

DROP TRIGGER IF EXISTS trg_lock_car_on_order;
DELIMITER $$
CREATE TRIGGER trg_lock_car_on_order
BEFORE INSERT ON sales_orders
FOR EACH ROW
BEGIN
    DECLARE v_vehicle_status VARCHAR(20);

    SELECT status INTO v_vehicle_status
    FROM inventory_vehicles
    WHERE vin = NEW.vin;

    IF v_vehicle_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '下单失败：VIN不存在';
    END IF;

    IF v_vehicle_status <> '在库' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '下单失败：车辆不在可销售库存状态';
    END IF;

    UPDATE inventory_vehicles
    SET status = '已锁定'
    WHERE vin = NEW.vin;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_update_inventory_on_delivery;
DELIMITER $$
CREATE TRIGGER trg_update_inventory_on_delivery
BEFORE UPDATE ON sales_orders
FOR EACH ROW
BEGIN
    IF NEW.order_status = '已完成' AND OLD.order_status <> '已完成' THEN
        SET NEW.delivered_at = COALESCE(NEW.delivered_at, NOW());

        UPDATE inventory_vehicles
        SET status = '已售出',
            sold_at = NEW.delivered_at
        WHERE vin = NEW.vin;
    END IF;

    IF NEW.order_status = '已取消' AND OLD.order_status IN ('待定金', '待交付') THEN
        UPDATE inventory_vehicles
        SET status = '在库'
        WHERE vin = NEW.vin
          AND status = '已锁定';
    END IF;
END$$
DELIMITER ;
