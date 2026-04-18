DROP DATABASE IF EXISTS car_sales;
CREATE DATABASE car_sales CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE car_sales;

CREATE TABLE brands (
    brand_id INT PRIMARY KEY AUTO_INCREMENT,
    brand_name VARCHAR(50) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE car_models (
    model_id INT PRIMARY KEY AUTO_INCREMENT,
    brand_id INT NOT NULL,
    series_name VARCHAR(100) NOT NULL,
    model_year SMALLINT NOT NULL,
    trim_name VARCHAR(100) NOT NULL,
    guide_price DECIMAL(12,2) NOT NULL,
    displacement VARCHAR(20) NOT NULL,
    vehicle_type VARCHAR(30) NOT NULL,
    safety_stock INT NOT NULL DEFAULT 2,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_model_brand FOREIGN KEY (brand_id) REFERENCES brands(brand_id),
    CONSTRAINT uq_model UNIQUE (brand_id, series_name, model_year, trim_name)
) ENGINE=InnoDB;

CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_no VARCHAR(20) NOT NULL UNIQUE,
    employee_name VARCHAR(50) NOT NULL,
    role_name VARCHAR(30) NOT NULL,
    department VARCHAR(30) NOT NULL,
    supervisor_id INT NULL,
    hire_date DATE NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_supervisor FOREIGN KEY (supervisor_id) REFERENCES employees(employee_id)
) ENGINE=InnoDB;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(50) NOT NULL,
    gender ENUM('男','女','未知') NOT NULL DEFAULT '未知',
    phone VARCHAR(20) NOT NULL UNIQUE,
    id_card VARCHAR(30) NOT NULL UNIQUE,
    address VARCHAR(255) NULL,
    first_visit_date DATE NOT NULL,
    source_channel VARCHAR(30) NOT NULL DEFAULT '到店',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE customer_intentions (
    intention_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    intended_model_id INT NOT NULL,
    intention_level ENUM('高','中','低') NOT NULL,
    notes VARCHAR(500) NULL,
    follow_up_consultant_id INT NOT NULL,
    next_contact_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_intention_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_intention_model FOREIGN KEY (intended_model_id) REFERENCES car_models(model_id),
    CONSTRAINT fk_intention_consultant FOREIGN KEY (follow_up_consultant_id) REFERENCES employees(employee_id)
) ENGINE=InnoDB;

CREATE TABLE inventory_vehicles (
    vin CHAR(17) PRIMARY KEY,
    model_id INT NOT NULL,
    color VARCHAR(30) NOT NULL,
    engine_no VARCHAR(50) NOT NULL UNIQUE,
    production_date DATE NOT NULL,
    inbound_date DATE NULL,
    procurement_cost DECIMAL(12,2) NOT NULL,
    suggested_retail_price DECIMAL(12,2) NOT NULL,
    status ENUM('在途','在库','已锁定','已售出') NOT NULL DEFAULT '在途',
    sold_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_vehicle_model FOREIGN KEY (model_id) REFERENCES car_models(model_id)
) ENGINE=InnoDB;

CREATE TABLE sales_orders (
    order_no VARCHAR(32) PRIMARY KEY,
    customer_id INT NOT NULL,
    sales_consultant_id INT NOT NULL,
    vin CHAR(17) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    deposit_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    order_status ENUM('草稿','待定金','待交付','已完成','已取消') NOT NULL DEFAULT '草稿',
    payment_method ENUM('现金','贷款','分期','转账') NOT NULL DEFAULT '转账',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at DATETIME NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_order_employee FOREIGN KEY (sales_consultant_id) REFERENCES employees(employee_id),
    CONSTRAINT fk_order_vehicle FOREIGN KEY (vin) REFERENCES inventory_vehicles(vin),
    CONSTRAINT chk_amount_valid CHECK (total_amount >= 0 AND deposit_amount >= 0 AND deposit_amount <= total_amount)
) ENGINE=InnoDB;

CREATE TABLE sales_order_items (
    item_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_no VARCHAR(32) NOT NULL,
    item_type ENUM('车辆','选装','保险','其他') NOT NULL,
    item_desc VARCHAR(200) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_item_order FOREIGN KEY (order_no) REFERENCES sales_orders(order_no)
) ENGINE=InnoDB;

CREATE TABLE service_orders (
    service_order_no VARCHAR(32) PRIMARY KEY,
    customer_id INT NOT NULL,
    vin CHAR(17) NOT NULL,
    service_type ENUM('保养','维修','质保','美容') NOT NULL,
    service_advisor_id INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expected_finish_at DATETIME NULL,
    total_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
    status ENUM('已创建','进行中','已完成','已取消') NOT NULL DEFAULT '已创建',
    CONSTRAINT fk_service_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_service_vehicle FOREIGN KEY (vin) REFERENCES inventory_vehicles(vin),
    CONSTRAINT fk_service_advisor FOREIGN KEY (service_advisor_id) REFERENCES employees(employee_id)
) ENGINE=InnoDB;

CREATE TABLE service_order_items (
    service_item_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    service_order_no VARCHAR(32) NOT NULL,
    item_name VARCHAR(120) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_service_item_order FOREIGN KEY (service_order_no) REFERENCES service_orders(service_order_no),
    CONSTRAINT chk_service_item_non_negative CHECK (quantity >= 0 AND unit_price >= 0 AND amount >= 0)
) ENGINE=InnoDB;
