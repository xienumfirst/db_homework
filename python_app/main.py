import json
import os
from typing import Any, Dict, List, Tuple

import pymysql


def load_db_config() -> Dict[str, Any]:
    config_path = os.getenv("DB_CONFIG_PATH", os.path.join(os.path.dirname(__file__), "config.json"))
    if not os.path.exists(config_path):
        raise FileNotFoundError(
            f"数据库配置文件不存在: {config_path}。请参考 config.example.json 创建配置文件。"
        )
    with open(config_path, "r", encoding="utf-8") as f:
        return json.load(f)


def get_connection():
    cfg = load_db_config()
    return pymysql.connect(
        host=cfg["host"],
        port=int(cfg.get("port", 3306)),
        user=cfg["user"],
        password=cfg["password"],
        database=cfg["database"],
        charset=cfg.get("charset", "utf8mb4"),
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=False,
    )


def print_rows(rows: List[Dict[str, Any]]) -> None:
    if not rows:
        print("(无数据)")
        return
    headers = list(rows[0].keys())
    print(" | ".join(headers))
    print("-" * 100)
    for row in rows:
        print(" | ".join(str(row.get(h, "")) for h in headers))


def sales_login() -> int:
    employee_id = int(input("请输入销售顾问ID: ").strip())
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT employee_id FROM employees WHERE employee_id=%s AND role_name='销售顾问'",
                (employee_id,),
            )
            row = cur.fetchone()
            if not row:
                raise ValueError("无效销售顾问ID")
    return employee_id


def create_intention_customer(sales_id: int) -> None:
    customer_name = input("客户姓名: ").strip()
    gender = input("性别(男/女/未知): ").strip() or "未知"
    phone = input("手机号: ").strip()
    id_card = input("身份证号: ").strip()
    address = input("地址: ").strip()
    source = input("来源渠道(到店/线上/转介绍): ").strip() or "到店"
    model_id = int(input("意向车型ID: ").strip())
    level = input("意向级别(高/中/低): ").strip() or "中"
    notes = input("备注: ").strip()
    next_contact = input("下次联系时间(YYYY-MM-DD HH:MM:SS, 可空): ").strip() or None

    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO customers (customer_name, gender, phone, id_card, address, first_visit_date, source_channel)
                    VALUES (%s, %s, %s, %s, %s, CURDATE(), %s)
                    """,
                    (customer_name, gender, phone, id_card, address, source),
                )
                customer_id = cur.lastrowid
                cur.execute(
                    """
                    INSERT INTO customer_intentions
                    (customer_id, intended_model_id, intention_level, notes, follow_up_consultant_id, next_contact_at)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (customer_id, model_id, level, notes, sales_id, next_contact),
                )
            conn.commit()
            print(f"创建成功，客户ID={customer_id}")
        except Exception as ex:
            conn.rollback()
            raise RuntimeError(f'创建意向客户失败: {ex}') from ex


def create_sales_order(sales_id: int) -> None:
    customer_id = int(input("客户ID: ").strip())
    vin = input("车辆VIN: ").strip()
    vehicle_amount = float(input("车辆成交价: ").strip())
    option_amount = float(input("选装金额(可为0): ").strip() or "0")
    insurance_amount = float(input("保险金额(可为0): ").strip() or "0")
    discount_amount = float(input("折扣金额(可为0): ").strip() or "0")
    deposit_amount = float(input("定金金额(可为0): ").strip() or "0")
    payment_method = input("付款方式(现金/贷款/分期/转账): ").strip() or "转账"

    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                cur.callproc(
                    "sp_create_sales_order",
                    [
                        customer_id,
                        sales_id,
                        vin,
                        vehicle_amount,
                        option_amount,
                        insurance_amount,
                        discount_amount,
                        deposit_amount,
                        payment_method,
                    ],
                )
                result = cur.fetchall()
            conn.commit()
            print("创建订单成功:")
            print_rows(result)
        except Exception as ex:
            conn.rollback()
            raise RuntimeError(f'创建销售订单失败: {ex}') from ex


def query_my_orders(sales_id: int) -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT order_no, customer_id, vin, total_amount, deposit_amount, order_status, created_at, delivered_at
                FROM sales_orders
                WHERE sales_consultant_id=%s
                ORDER BY created_at DESC
                """,
                (sales_id,),
            )
            print_rows(cur.fetchall())


def vehicle_inbound() -> None:
    vin = input("VIN(17位): ").strip()
    model_id = int(input("车型ID: ").strip())
    color = input("颜色: ").strip()
    engine_no = input("发动机号: ").strip()
    production_date = input("生产日期(YYYY-MM-DD): ").strip()
    inbound_date = input("入库日期(YYYY-MM-DD): ").strip()
    procurement_cost = float(input("采购成本: ").strip())
    suggested_price = float(input("建议零售价: ").strip())

    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO inventory_vehicles
                    (vin, model_id, color, engine_no, production_date, inbound_date, procurement_cost, suggested_retail_price, status)
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,'在库')
                    """,
                    (vin, model_id, color, engine_no, production_date, inbound_date, procurement_cost, suggested_price),
                )
            conn.commit()
            print("车辆入库成功")
        except Exception as ex:
            conn.rollback()
            raise RuntimeError(f'车辆入库失败: {ex}') from ex


def query_inventory() -> None:
    status = input("按状态筛选(在库/已锁定/已售出/在途，可空): ").strip()
    model_id = input("按车型ID筛选(可空): ").strip()

    sql = """
        SELECT v.vin, v.status, v.color, v.inbound_date, b.brand_name, m.series_name, m.trim_name
        FROM inventory_vehicles v
        JOIN car_models m ON v.model_id = m.model_id
        JOIN brands b ON m.brand_id = b.brand_id
        WHERE 1=1
    """
    params: List[Any] = []
    if status:
        sql += " AND v.status=%s"
        params.append(status)
    if model_id:
        sql += " AND v.model_id=%s"
        params.append(int(model_id))
    sql += " ORDER BY v.updated_at DESC"

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tuple(params))
            print_rows(cur.fetchall())


def view_inventory_warning() -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT brand_name, series_name, model_year, trim_name, safety_stock, in_stock_count
                FROM v_inventory_summary
                WHERE in_stock_count < safety_stock
                ORDER BY (safety_stock - in_stock_count) DESC
                """
            )
            print_rows(cur.fetchall())


def query_sales_ranking() -> None:
    year = int(input("年份(如2026): ").strip())
    quarter = int(input("季度(1-4): ").strip())
    period = f"{year}-Q{quarter}"

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT employee_name, order_count, sales_amount, gross_profit
                FROM v_sales_performance
                WHERE stat_quarter = %s
                ORDER BY sales_amount DESC
                """,
                (period,),
            )
            print_rows(cur.fetchall())


def query_top_models() -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT b.brand_name, m.series_name, m.trim_name, COUNT(*) AS sold_count
                FROM sales_orders so
                JOIN inventory_vehicles v ON so.vin = v.vin
                JOIN car_models m ON v.model_id = m.model_id
                JOIN brands b ON m.brand_id = b.brand_id
                WHERE so.order_status = '已完成'
                GROUP BY b.brand_name, m.series_name, m.trim_name
                ORDER BY sold_count DESC
                LIMIT 5
                """
            )
            print_rows(cur.fetchall())


def generate_monthly_report() -> None:
    year = int(input("年份(如2026): ").strip())
    month = int(input("月份(1-12): ").strip())
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.callproc("sp_get_monthly_report", [year, month])
            print_rows(cur.fetchall())


def sales_front_menu() -> None:
    sales_id = sales_login()
    while True:
        print("\n[销售前台] 1.创建意向客户 2.创建销售订单 3.查询我的订单 0.返回")
        choice = input("请选择: ").strip()
        if choice == "1":
            create_intention_customer(sales_id)
        elif choice == "2":
            create_sales_order(sales_id)
        elif choice == "3":
            query_my_orders(sales_id)
        elif choice == "0":
            break
        else:
            print("无效输入")


def inventory_menu() -> None:
    while True:
        print("\n[库存管理] 1.车辆入库 2.查询车辆库存 3.查看库存预警报表 0.返回")
        choice = input("请选择: ").strip()
        if choice == "1":
            vehicle_inbound()
        elif choice == "2":
            query_inventory()
        elif choice == "3":
            view_inventory_warning()
        elif choice == "0":
            break
        else:
            print("无效输入")


def report_center_menu() -> None:
    while True:
        print("\n[报表中心] 1.查询销售业绩榜 2.查询畅销车型排行 3.生成月度销售统计 0.返回")
        choice = input("请选择: ").strip()
        if choice == "1":
            query_sales_ranking()
        elif choice == "2":
            query_top_models()
        elif choice == "3":
            generate_monthly_report()
        elif choice == "0":
            break
        else:
            print("无效输入")


def main() -> None:
    while True:
        print("\n=== 汽车销售管理系统 ===")
        print("1. 销售前台")
        print("2. 库存管理")
        print("3. 报表中心")
        print("0. 退出")
        choice = input("请选择: ").strip()

        try:
            if choice == "1":
                sales_front_menu()
            elif choice == "2":
                inventory_menu()
            elif choice == "3":
                report_center_menu()
            elif choice == "0":
                print("已退出")
                break
            else:
                print("无效输入")
        except Exception as ex:
            print(f"操作失败: {ex}")


if __name__ == "__main__":
    main()
