USE car_sales;

DROP TRIGGER IF EXISTS trg_lock_car_on_order;
DELIMITER $$
CREATE TRIGGER trg_lock_car_on_order
BEFORE INSERT ON sales_orders
FOR EACH ROW
BEGIN
    DECLARE v_vehicle_exists INT DEFAULT 0;

    IF NEW.order_status = '已取消' THEN
        -- 已取消的历史/作废订单不占用库存，外键仍保证 VIN 存在。
        SET NEW.delivered_at = NULL;
    ELSEIF NEW.order_status = '已完成' THEN
        SET NEW.delivered_at = COALESCE(NEW.delivered_at, NOW());

        UPDATE inventory_vehicles
        SET status = '已售出',
            sold_at = NEW.delivered_at
        WHERE vin = NEW.vin
          AND status = '在库';

        IF ROW_COUNT() = 0 THEN
            SELECT COUNT(*) INTO v_vehicle_exists
            FROM inventory_vehicles
            WHERE vin = NEW.vin;

            IF v_vehicle_exists = 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '下单失败：VIN不存在';
            ELSE
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '下单失败：车辆不在可销售库存状态';
            END IF;
        END IF;
    ELSE
        UPDATE inventory_vehicles
        SET status = '已锁定'
        WHERE vin = NEW.vin
          AND status = '在库';

        IF ROW_COUNT() = 0 THEN
            SELECT COUNT(*) INTO v_vehicle_exists
            FROM inventory_vehicles
            WHERE vin = NEW.vin;

            IF v_vehicle_exists = 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '下单失败：VIN不存在';
            ELSE
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '下单失败：车辆不在可销售库存状态';
            END IF;
        END IF;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_update_inventory_on_delivery;
DELIMITER $$
CREATE TRIGGER trg_update_inventory_on_delivery
BEFORE UPDATE ON sales_orders
FOR EACH ROW
BEGIN
    IF NEW.vin <> OLD.vin THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '不允许修改销售订单关联VIN';
    END IF;

    IF OLD.order_status = '已完成' AND NEW.order_status <> '已完成' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '已完成订单不允许回退状态';
    END IF;

    IF NEW.order_status = '已完成' AND OLD.order_status <> '已完成' THEN
        SET NEW.delivered_at = COALESCE(NEW.delivered_at, NOW());

        UPDATE inventory_vehicles
        SET status = '已售出',
            sold_at = NEW.delivered_at
        WHERE vin = NEW.vin
          AND status IN ('在库', '已锁定');

        IF ROW_COUNT() = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '交付失败：车辆状态不允许售出';
        END IF;
    END IF;

    IF NEW.order_status = '已取消' AND OLD.order_status IN ('待定金', '待交付') THEN
        UPDATE inventory_vehicles
        SET status = '在库'
        WHERE vin = NEW.vin
          AND status = '已锁定';
    END IF;
END$$
DELIMITER ;
