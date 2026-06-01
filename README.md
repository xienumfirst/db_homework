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

## Data download（故障排查）

如果你使用的是历史保存的 S3 预签名 URL，出现 `AccessDenied` / `Request has expired` 通常是因为链接中的 `X-Amz-Expires` 已到期。预签名 URL 本身是临时授权，不可长期复用。

- 重新获取可用链接：
  - 回到原始数据集发布页面，复制最新下载链接；
  - 或回到项目 README / 文档中的数据下载入口，使用当前提供的链接。
- 使用建议：
  - 文档中优先保留稳定入口链接（数据集主页），避免直接长期保存单个预签名 URL；
  - 如需自动化下载，建议用脚本从稳定入口获取/刷新最新可用下载地址后再拉取文件。

### 截图说明

建议在提交问题或复现记录时附上两类截图（可脱敏）：

1. 过期链接报错页面（包含 `AccessDenied` 或 `Request has expired` 关键信息）；
2. 从数据集页面/README 重新获取新链接后可正常下载的页面。

可参考命名：`docs/images/system_test/S4_data_download_presigned_url_expired.png`。
