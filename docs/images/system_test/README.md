# 系统测试截图归档说明

本目录用于存放《数据库系统》课程大作业“任务六：系统测试”截图证据。

## 命名规范

- 文件名格式：`S{步骤序号}_TC{用例号}_{场景}.png`
- 示例：`S3_TC01_create_order_success.png`

## 最低提交清单

1. `S1_init_sql_success.png`：SQL 01~06 执行成功
2. `S2_q2_sales_ranking.png`：Q2 顾问业绩排行
3. `S2_q7_inventory_warning.png`：Q7 库存预警
4. `S3_tc01_order_lock_before_after.png`：规则A（下单锁车）
5. `S3_tc02_delivery_sold_before_after.png`：规则B（交付售出）
6. `S3_tc04_transaction_rollback.png`：非法下单回滚
7. `S3_python_menu_flow.png`：Python 三大菜单联调

## 截图建议

- 截图中保留时间、SQL/命令输入与关键输出字段；
- 同一用例尽量保留“前置状态 + 操作结果 + 核验结果”三段证据；
- 若包含敏感连接信息（账号/密码），提交前请遮挡。
