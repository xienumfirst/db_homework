# db_homework

汽车销售管理系统课程大作业实现（SQL + Python）。

## 目录说明

- `sql/01_create_schema.sql`：建库建表
- `sql/02_init_data.sql`：初始化模拟数据
- `sql/03_views.sql`：视图
- `sql/04_indexes.sql`：索引
- `sql/05_triggers.sql`：触发器
- `sql/06_procedures.sql`：存储过程
- `sql/07_queries.sql`：复杂查询（Q1-Q8）
- `python_app/main.py`：控制台应用
- `docs/数据库设计说明书.md`：设计文档
- `docs/系统测试文档.md`：测试文档
- `docs/课程设计报告.md`：课程报告

## 运行步骤

1. 安装依赖：
   ```bash
   cd python_app
   pip install -r requirements.txt
   ```
2. 配置数据库连接：
   - 复制 `python_app/config.example.json` 为 `python_app/config.json`
   - 填写 MySQL 连接信息
3. 在 MySQL 中按顺序执行 `sql/01` 到 `sql/06` 脚本。
4. 执行 `sql/07_queries.sql` 查看查询结果。
5. 启动应用：
   ```bash
   cd python_app
   python main.py
   ```
