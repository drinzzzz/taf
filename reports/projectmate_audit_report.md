# ProjectMate 系统架构/安全/可靠性审计报告

**审计日期**: 2025-06-13  
**审计人员**: Hermes Agent  
**服务器**: DW (124.221.119.232)  
**代码路径**: /www/wwwroot/project_mate/  
**API 端口**: 8000 (gunicorn)

---

## 执行摘要

| 类别 | 评分 | 状态 |
|------|------|------|
| **安全性** | 7.5/10 | ⚠️ 需改进 |
| **架构一致性** | 6/10 | 🔴 存在严重问题 |
| **可靠性** | 8/10 | ⚠️ 需改进 |
| **综合评分** | **7.2/10** | **需立即修复** |

---

## 1. 安全性审计 (7.5/10)

### 1.1 认证流程 ✓ 良好

**发现**:
- `middleware/auth.py` 实现了统一的 token 验证中间件
- 支持三种 token 传递方式：Cookie > Authorization Bearer > Query Parameter
- `services/auth_service.py` 使用 bcrypt 哈希密码，支持旧版 SHA256 自动升级
- Session token 存储在 `auth_tokens` 表，带过期时间和使用标记
- 登录失败审计日志记录到 `audit_logs` 表

**优点**:
- 密码哈希使用 bcrypt（新用户）或自动升级（旧用户）
- Token 验证通过 SQL 参数化查询，防止注入
- httpOnly cookie 设置正确

**建议**:
- [ ] 考虑添加 token 刷新机制而非长期有效 (当前 60 天)
- [ ] 添加登录失败次数限制后的账户锁定机制

### 1.2 SQL 注入防护 ✓ 良好

**发现**:
- 所有数据库查询使用参数化查询 (`%s` 占位符)
- 动态 SQL 构建使用白名单过滤字段名 (如 `update_project` 的 `ALLOWED_FIELDS`)

**示例** (`services/project_service.py`):
```python
ALLOWED_FIELDS = {"name", "client_id", "address", "status", ...}
for k, v in data.items():
    if v is None or k not in ALLOWED_FIELDS:
        continue
    fields.append(f"{k}=%s")
```

### 1.3 Access Control ✓ 良好

**发现**:
- `services/project_access_service.py` 提供统一的权限检查
- `check_project_access(user_id, project_id)` 验证用户对项目的访问权限
- 所有受保护端点使用 `get_current_user` Depends 注入

**测试验证**:
- 删除不存在的事件/里程碑返回 403 (预期行为)
- 项目列表正确过滤为当前用户的项目

### 1.4 硬编码凭证 ⚠️ 中等风险

**发现**:
- `.env` 文件存在但敏感信息使用加密 (`utils/crypto.py`)
- `config.py` 从环境变量读取数据库密码
- 坚果云凭证存储在配置中 (`NUTSTORE_ACCOUNT`, `NUTSTORE_PASS`)

**建议**:
- [ ] 考虑使用外部密钥管理服务 (如 AWS Secrets Manager)
- [ ] 定期轮换数据库密码

### 1.5 Token 处理 ✓ 良好

**发现**:
- Token 使用 `secrets.token_hex(32)` 生成，足够随机
- Token 验证检查过期时间和 `is_used` 标记
- 登出时设置 `is_used=1` 使 token 失效

---

## 2. 架构一致性审计 (6/10) 🔴 严重问题

### 2.1 数据库 Schema 验证 ✓ 正确

**确认**: `projects.user_id` 已成功迁移为 `INT` 类型
```sql
Field   Type    Null    Key     Default    Extra
user_id int     NO      MUL     NULL
```

### 2.2 类型一致性 🔴 严重问题

**发现的关键 Bug**:

#### Bug #1: `nlp_engine.py` (严重)

**位置**: 第 94 行 `_find_project()` 函数
```python
def _find_project(weixin_uid: str, project_name: str) -> Optional[dict]:
    ...
    cur.execute("SELECT * FROM projects WHERE user_id=%s", (weixin_uid,))  # 🔴 BUG
```

**问题**: `weixin_uid` 是字符串 (如 `"o9cq802wAFKg8P5dLumCw52SE4No@im.wechat"`)，但 `projects.user_id` 是 `INT`。MySQL 会进行隐式类型转换，但可能导致：
1. 查询失败 (取决于 MySQL 模式)
2. 性能问题 (无法使用索引)
3. 逻辑错误 (字符串 "8" 和整数 8 在某些情况下不等价)

**影响范围**: 
- NLP 消息分析功能
- 会议纪要处理功能
- 所有通过微信创建/查询项目的功能

#### Bug #2: `query_handlers.py` (严重)

**位置**: 第 277-390 行 `query_today()` 函数
```python
def query_today(weixin_uid: str) -> str:
    ...
    cur.execute("""SELECT ... FROM projects p ... WHERE p.user_id=%s""", (weixin_uid, today))  # 🔴 BUG
```

**问题**: 多处 SQL 查询使用 `weixin_uid` (字符串) 查询 `user_id` (整数)
- 第 303 行：今日里程碑查询
- 第 325 行：今日任务查询
- 第 354 行：今日工单查询
- 第 375 行：待处理工单计数
- 第 390 行：今日收款查询

**影响范围**: 
- 微信"今日安排"查询功能
- 所有日报/晚报中依赖 `query_today` 的功能

#### Bug #3: `meeting_parser.py` (严重)

**位置**: 第 54 行
```python
proj = _find_project(weixin_uid, project_name)  # 🔴 调用有 bug 的函数
```

**影响范围**: 会议纪要处理功能

#### Bug #4: `evening_report.py` (中等)

**位置**: 第 43 行函数签名 vs 第 230 行默认值
```python
def build_evening_report(user_id: int) -> str:  # 签名是 int
    ...

if __name__ == "__main__":
    user_id = sys.argv[1] if len(sys.argv) > 1 else "o9cq802wAFKg8P5dLumCw52SE4No@im.wechat"  # 🔴 默认值是字符串
```

**问题**: 函数签名声明 `user_id: int`，但命令行默认值是微信 UID 字符串

#### Bug #5: `services/auth_service.py` (中等)

**位置**: 第 63-73 行 `get_all_users()` 函数
```python
def get_all_users() -> list:
    ...
    cur.execute("""
        SELECT u.id, u.username, ...,
               (SELECT COUNT(*) FROM projects p WHERE p.user_id=u.username) AS project_count,
               ...
        FROM users u ...
    """)
```

**问题**: 子查询中 `p.user_id=u.username` 比较整数和字符串，这是迁移遗留的 bug

**影响范围**: 管理员用户列表 API

### 2.3 语义化改名验证 ✓ 部分完成

**已确认的改名**:
- `msg_uid` → `msg_username` (消息处理)
- NLP 中的 `user_id` → `weixin_uid` (微信用户标识符)
- nutstore 中的 `user_id` → `username` (用户名)

**残留问题**:
- `query_handlers.py` 仍使用 `weixin_uid` 参数名但实际应该用 `user_id` (整数)
- `nlp_engine.py` 的 `weixin_uid` 应该改为 `user_id` (整数)

---

## 3. 可靠性审计 (8/10)

### 3.1 API 端点测试 ✓ 全部通过

**测试结果** (5/5 通过):
```
PASS: Projects List (200, 返回 67 条项目)
PASS: Schedules/Milestones (200)
PASS: Schedule Summary (200)
PASS: Nutstore Links (200)
PASS: Delete Endpoints (403 - 预期行为)
```

### 3.2 类型转换边界 ⚠️ 需关注

**发现**:
- 大多数服务函数正确使用 `user_id: int` 类型注解
- `services/project_service.py` ✓ 正确
- `services/schedule_service.py` ✓ 正确
- `services/nutstore_service.py` ✓ 正确

**问题**: NLP 相关模块未跟随类型变更

### 3.3 空值处理 ✓ 良好

**发现**:
- 大多数函数使用 `Optional` 类型注解
- 数据库查询结果使用 `row_to_dict()` 处理 None
- Pydantic schema 使用 `Field(None, ...)` 处理可选字段

### 3.4 错误恢复 ⚠️ 需改进

**发现**:
- `nutstore_service.py` 有完善的 503 限流重试机制
- `nlp_engine.py` 的 AI 调用有 try/except 包裹
- 部分函数静默失败 (如 `_log_llm_usage`)

**建议**:
- [ ] 添加统一的错误日志记录
- [ ] 关键操作添加事务回滚

### 3.5 多租户隔离 ✓ 良好

**发现**:
- `middleware/tenant_middleware.py` 实现租户隔离
- 数据库名从 `platform_meta.tenants` 动态获取
- 租户缓存机制 (`tenant_db_cache.json`) 减少平台库查询

---

## 4. 最近改动验证

### 4.1 `projects.user_id` varchar→int 迁移 ✓ 完成

**验证**:
- 数据库 schema 确认 `user_id INT`
- 67 条项目数据全部映射到 `uid=8`
- `models/schemas.py` 的 `ProjectCreate.user_id` 已改为 `int`

### 4.2 全局改名 ⚠️ 部分完成

**已完成**:
- 服务层参数名更新
- Router 层参数名更新
- Schema 定义更新

**未完成**:
- NLP 模块仍使用 `weixin_uid` (字符串) 查询整数 `user_id`
- `query_handlers.py` 仍使用 `weixin_uid` (字符串)

### 4.3 涉及文件检查

| 文件 | 状态 | 备注 |
|------|------|------|
| `services/project_service.py` | ✓ 正确 | `user_id: int` |
| `services/schedule_service.py` | ✓ 正确 | `user_id: int` |
| `services/transaction_service.py` | 待检查 | - |
| `services/invoice_service.py` | 待检查 | - |
| `services/memo_service.py` | ✓ 正确 | `user_id: int` |
| `services/quotation_service.py` | 待检查 | - |
| `services/task_service.py` | 待检查 | - |
| `services/nutstore_service.py` | ✓ 正确 | `username: str` |
| `routers/schedules.py` | ✓ 正确 | 使用 `user["id"]` |
| `routers/nutstore.py` | ✓ 正确 | 使用 `user["id"]` |
| `nlp_engine.py` | 🔴 有 Bug | `weixin_uid` 类型错误 |
| `query_handlers.py` | 🔴 有 Bug | `weixin_uid` 类型错误 |
| `meeting_parser.py` | 🔴 有 Bug | 调用有 bug 的函数 |
| `daily_report.py` | ✓ 正确 | `user_id: int` |
| `evening_report.py` | ⚠️ 有 Bug | 默认值是字符串 |

---

## 5. 关键 Bug 修复建议

### 紧急修复 (P0 - 立即修复)

#### 1. 修复 `nlp_engine.py` 的 `_find_project()` 函数

**当前代码**:
```python
def _find_project(weixin_uid: str, project_name: str) -> Optional[dict]:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM projects WHERE user_id=%s", (weixin_uid,))  # BUG
```

**修复方案**:
```python
def _find_project(user_id: int, project_name: str) -> Optional[dict]:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM projects WHERE user_id=%s", (user_id,))
```

**调用方需要同步修改**:
- `analyze_message()` 函数
- `process_meeting_minutes()` 函数
- `_do_create_meeting()` 函数

#### 2. 修复 `query_handlers.py` 的查询函数

**当前代码**:
```python
def query_project_status(project_id: int, weixin_uid: str) -> str:
def query_finance(project_id: int, weixin_uid: str) -> str:
def query_today(weixin_uid: str) -> str:
```

**修复方案**:
```python
def query_project_status(project_id: int, user_id: int) -> str:
def query_finance(project_id: int, user_id: int) -> str:
def query_today(user_id: int) -> str:
```

并修改所有 SQL 查询中的参数传递。

#### 3. 修复 `services/auth_service.py` 的 `get_all_users()`

**当前代码**:
```python
cur.execute("""
    SELECT ...,
           (SELECT COUNT(*) FROM projects p WHERE p.user_id=u.username) AS project_count
    FROM users u ...
""")
```

**修复方案**:
```python
cur.execute("""
    SELECT ...,
           (SELECT COUNT(*) FROM projects p WHERE p.user_id=u.id) AS project_count
    FROM users u ...
""")
```

#### 4. 修复 `evening_report.py` 的默认值

**当前代码**:
```python
if __name__ == "__main__":
    user_id = sys.argv[1] if len(sys.argv) > 1 else "o9cq802wAFKg8P5dLumCw52SE4No@im.wechat"
```

**修复方案**:
```python
if __name__ == "__main__":
    user_id = int(sys.argv[1]) if len(sys.argv) > 1 else 8  # 或从配置读取
```

### 中期改进 (P1 - 本周内)

1. **统一命名规范**:
   - `user_id`: 始终表示数据库用户 ID (整数)
   - `username`: 用户名 (字符串)
   - `weixin_uid`: 微信用户 ID (字符串，仅用于微信相关表)

2. **添加类型检查**:
   - 在关键函数入口添加 `isinstance(user_id, int)` 检查
   - 考虑使用 Pydantic 进行运行时验证

3. **完善测试覆盖**:
   - 为 NLP 模块添加单元测试
   - 为查询处理器添加集成测试

---

## 6. 其他发现

### 6.1 代码质量优点

- 使用参数化查询防止 SQL 注入
- 使用白名单验证动态字段名
- 完善的错误处理和日志记录
- 清晰的模块分层 (routers → services → models)

### 6.2 潜在改进点

1. **连接池配置**: 已配置 SQLAlchemy 连接池，但未在所有地方使用
2. **事务管理**: 部分多步骤操作缺少事务包裹
3. **API 文档**: 缺少 OpenAPI/Swagger 文档
4. **监控告警**: 缺少系统监控和告警机制

---

## 7. 结论

ProjectMate 系统在安全性方面表现良好，但在最近的用户 ID 类型迁移中存在**严重的架构一致性问题**。NLP 和查询处理模块未跟随类型变更，导致核心功能可能失效。

**优先级**:
1. **立即修复** NLP 和 query_handlers 的类型 bug (P0)
2. **本周内** 完成所有残留的类型问题修复 (P1)
3. **本月内** 添加完善的测试覆盖 (P2)

**综合评分**: 7.2/10

---

**报告生成**: Hermes Agent  
**时间**: 2025-06-13
