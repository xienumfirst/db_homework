USE car_sales;

-- 优化按时间范围统计订单（Q1/Q2/月报）
CREATE INDEX idx_sales_orders_created_at ON sales_orders (created_at);

-- 优化按销售顾问+状态查询订单列表（我的订单/业绩分析）
CREATE INDEX idx_sales_orders_consultant_status ON sales_orders (sales_consultant_id, order_status);

-- 优化库存按状态+车型聚合统计（库存汇总/预警）
CREATE INDEX idx_inventory_status_model ON inventory_vehicles (status, model_id);

-- 优化客户手机号精确查找（客户检索）
CREATE INDEX idx_customers_phone ON customers (phone);

-- 优化订单明细按订单号及类型聚合（订单金额分析）
CREATE INDEX idx_order_items_order_type ON sales_order_items (order_no, item_type);

-- 优化售后按客户及时间查询历史
CREATE INDEX idx_service_orders_customer_created ON service_orders (customer_id, created_at);

-- 优化意向客户跟进计划查询
CREATE INDEX idx_intentions_next_contact ON customer_intentions (next_contact_at);
