# 后端辅助业务路由代码审计报告

**项目**: project_mate  
**技术栈**: Python FastAPI + PostgreSQL + PyMySQL  
**审计日期**: 2026-06-06  
**审计范围**: 7个路由文件 + 6个服务文件  

---

## 执行摘要

| 维度 | 平均分 | 评级 |
|------|--------|------|
| 代码质量 | 7.4/10 | 中等 |
| 安全性 | 6.6/10 | 需改进 |
| 输入校验 | 6.6/10 | 需改进 |
| 错误处理 | 6.6/10 | 需改进 |
| 数据库操作 | 7.9/10 | 良好 |

**关键发现**: 存在3个高危问题、7个中危问题，建议优先修复认证不一致和SQL注入风险。

---

## 1. routers/auth.py (428行) — 认证模块

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 7/10 | 结构清晰，但存在重复代码（cookie设置逻辑重复3次） |
| 安全性 | 5/10 | ⚠️ 严重：未使用`Depends(get_current_user)`，手动token校验不一致 |
| 输入校验 | 7/10 | 有基础校验（密码长度、文件类型/大小），但不够严格 |
| 错误处理 | 6/10 | 部分异常被静默忽略（如session_days读取失败） |
| 数据库 | 8/10 | 使用参数化查询，连接管理良好 |

### 亮点
- ✅ 使用bcrypt加密密码，支持旧密码自动升级
- ✅ 登录失败审计日志记录完整
- ✅ 支持httpOnly cookie，安全属性配置正确（secure=True, samesite="lax"）
- ✅ 速率限制（limiter）应用于登录/注册接口

### 问题

#### 🔴 高危
1. **认证机制不一致** (第220-371行): 
   - `get_profile`, `update_profile`, `change_password`, `list_users`, `admin_update_user` 等接口使用 `token: str = Query(...)` 手动校验
   - 未使用标准的 `Depends(get_current_user)`，导致认证逻辑分散
   - 部分接口token参数非强制（`Query(None)`），可能被绕过

2. **debug-login后门风险** (第155-196行):
   - 内测模式允许无密码登录，仅需用户名
   - beta_mode开关存储在数据库中，可能被SQL注入或其他漏洞利用
   - 生产环境应完全移除此功能

3. **密码强度要求过低** (第102行, 第320行):
   - 密码最小长度仅4位：`len(data.password) < 4`
   - 无复杂度要求（大小写、数字、特殊字符）
   - 建议：最小8位，包含字母+数字

#### 🟡 中危
4. **Session过期时间过长** (第65-78行):
   - 默认60天，从数据库读取但失败时静默使用默认值
   - 建议：敏感系统session不超过7天

5. **文件上传校验不足** (第373-416行):
   - 仅检查content_type，未验证文件实际内容（魔数）
   - 攻击者可上传恶意文件伪装成图片
   - 建议：添加文件头校验

6. **重复代码**:
   - Cookie设置逻辑在`/login`, `/debug-login`, `/switch-user`, `/avatar`中重复4次
   - 建议：抽取为公共函数

---

## 2. routers/dashboard.py (215行) — 仪表盘

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 6/10 | SQL查询复杂，动态拼接存在风险 |
| 安全性 | 5/10 | ⚠️ 未认证用户可访问基础统计数据 |
| 输入校验 | N/A | 只读接口为主 |
| 错误处理 | 6/10 | 异常处理不完整 |
| 数据库 | 7/10 | 复杂JOIN查询，动态SQL拼接风险 |

### 亮点
- ✅ 合并多个独立SQL为单次JOIN+GROUP BY查询（P2-15/16优化）
- ✅ 使用`get_project_id_sql_filter`进行数据权限隔离

### 问题

#### 🔴 高危
1. **未认证访问** (第36-45行):
   ```python
   if not user:
       return base  # 返回空统计数据
   ```
   - `_dashboard_current_user`认证失败返回None而非抛出异常
   - 攻击者可获取系统基础统计信息（项目总数、工单数等）
   - 建议：始终要求认证，或明确公开接口

#### 🟡 中危
2. **SQL注入风险** (第73-78行):
   ```python
   filter_clause = pf if pf else ""
   if filter_clause and "WHERE" not in stats_sql.upper():
       stats_sql = stats_sql.replace("FROM projects p", "FROM projects p " + filter_clause.replace("AND", "WHERE", 1), 1)
   ```
   - `get_project_id_sql_filter`返回的filter_clause直接拼接到SQL
   - 虽然该函数内部使用参数化，但拼接方式增加了风险面
   - 建议：重构为完全参数化查询

3. **复杂SQL难以维护** (第55-193行):
   - 单个函数包含15+个统计查询
   - 建议：拆分为独立服务函数

---

## 3. routers/invoices.py (77行) — 发票管理

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 结构清晰，职责单一 |
| 安全性 | 8/10 | 正确使用Depends和权限检查 |
| 输入校验 | 7/10 | 依赖Pydantic schemas |
| 错误处理 | 7/10 | 基础HTTPException处理 |
| 数据库 | 8/10 | 服务层参数化查询 |

### 亮点
- ✅ 统一使用 `Depends(get_current_user)` 认证
- ✅ 所有写操作检查项目访问权限 (`check_project_access`)
- ✅ 删除操作验证用户所有权

### 问题

#### 🟡 中危
1. **GET接口缺少权限验证** (第23-32行):
   - `api_list_invoices` 和 `api_invoice_stats` 仅通过`allowed_pids`过滤
   - 未显式验证用户是否有权访问指定project_id
   - 建议：添加project_id存在性和权限检查

2. **Pydantic schema验证不足**:
   - `InvoiceCreateRequestFull` 和 `InvoiceUpdateRequestFull` 未查看定义
   - 建议：确保金额、税率等字段有合理范围限制

---

## 4. routers/memos.py (74行) — 工单管理

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 简洁清晰 |
| 安全性 | 8/10 | 认证和权限检查完整 |
| 输入校验 | 6/10 | Query参数直接使用，缺少验证 |
| 错误处理 | 7/10 | 基础处理 |
| 数据库 | 8/10 | 服务层处理良好 |

### 亮点
- ✅ 统一认证模式
- ✅ 项目权限检查

### 问题

#### 🟡 中危
1. **Query参数无验证** (第12-24行):
   ```python
   status: str = Query(""),
   category: str = Query(""),
   memo_mode: str = Query(""),
   limit: int = Query(50),
   ```
   - `limit` 无最大值限制，可能导致DoS（如limit=1000000）
   - `memo_mode` 无枚举校验，虽然服务层有处理但应在路由层拒绝非法值
   - 建议：添加`Query(50, le=200)`等约束

2. **创建接口参数松散** (第27-39行):
   - `title`, `content` 为空字符串时允许创建
   - 建议：添加最小长度要求

---

## 5. routers/schedules.py (160行) — 工期管理

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 组织良好，分组清晰 |
| 安全性 | 8/10 | 认证和权限完整 |
| 输入校验 | 7/10 | 必填字段检查 |
| 错误处理 | 7/10 | 基础处理 |
| 数据库 | 8/10 | 服务层处理 |

### 亮点
- ✅ 路由按功能分组（工期总表、时间线事件、里程碑）
- ✅ 所有接口均有项目权限检查
- ✅ 删除操作验证用户权限

### 问题

#### 🟡 中危
1. **必填字段检查不完整** (第86-91行):
   ```python
   if not data.project_id or not data.event_date or not data.title:
   ```
   - 仅检查空值，未验证日期格式、长度等
   - 建议：在Pydantic schema中定义验证规则

2. **更新接口权限检查逻辑** (第100-102行):
   ```python
   if data.project_id and data.project_id > 0 and not check_project_access(...)
   ```
   - 仅当data中包含project_id时才检查
   - 但更新事件时可能通过其他字段间接影响权限
   - 建议：始终验证事件所属项目的权限

---

## 6. routers/tasks.py (42行) — 任务管理

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 简单清晰 |
| 安全性 | 8/10 | 认证完整 |
| 输入校验 | 6/10 | 最小验证 |
| 错误处理 | 6/10 | 最简处理 |
| 数据库 | 8/10 | 服务层处理 |

### 亮点
- ✅ 简洁的RESTful设计
- ✅ 使用项目权限过滤

### 问题

#### 🟡 中危
1. **任务日期无验证** (第16-19行):
   - `task_date: str` 无格式验证
   - 建议：使用`date`类型或添加正则校验

2. **状态更新无权限检查** (第36-42行):
   ```python
   async def api_update_task(task_id: int, status: str, user: dict = Depends(get_current_user)):
       return {"success": update_task_status(task_id, status)}
   ```
   - 未验证用户是否有权更新此任务（任务可能属于其他项目）
   - `update_task_status`服务函数也未检查权限
   - 建议：添加任务所属项目权限验证

3. **状态值无枚举校验**:
   - `status: str` 可接受任意值
   - 虽然服务层有默认值处理，但应在路由层拒绝非法值

---

## 7. routers/transactions.py (44行) — 收支管理

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 简洁 |
| 安全性 | 8/10 | 认证和权限完整 |
| 输入校验 | 6/10 | Query参数无验证 |
| 错误处理 | 6/10 | 基础处理 |
| 数据库 | 8/10 | 服务层处理 |

### 亮点
- ✅ 项目权限检查
- ✅ 使用Depends认证

### 问题

#### 🟡 中危
1. **金额无验证** (第23-44行):
   - `amount: float` 无范围限制（可为负数或超大值）
   - 建议：添加`Field(gt=0, lt=100000000)`约束

2. **类型参数无枚举校验**:
   - `type_: str` 应为`income`或`expense`
   - `invoice_status: str = "none"` 无枚举限制
   - 建议：使用Enum类型或Literal

---

## 服务层审计摘要

### services/auth_service.py (138行)
| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 结构清晰 |
| 安全性 | 8/10 | bcrypt加密，参数化查询 |
| 数据库 | 9/10 | 连接管理良好 |

**亮点**: 
- ✅ bcrypt密码加密，支持旧SHA256自动升级
- ✅ 所有SQL使用参数化查询

**问题**:
- ⚠️ `verify_and_upgrade_password`升级失败时静默忽略（第63-64行）
- ⚠️ `get_all_users`查询暴露敏感信息（storage_quota, project_limit）

---

### services/memo_service.py (171行)
| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 良好 |
| 安全性 | 8/10 | 字段白名单，权限检查 |
| 数据库 | 8/10 | 事务处理完整 |

**亮点**:
- ✅ 更新操作使用ALLOWED_FIELDS白名单
- ✅ 删除操作验证项目权限
- ✅ 事务回滚处理

---

### services/invoice_service.py (210行)
| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 良好 |
| 安全性 | 8/10 | 字段白名单，参数化查询 |
| 数据库 | 8/10 | 参数化查询 |

**亮点**:
- ✅ 代码注释明确说明SQL注入防护措施
- ✅ 字段白名单验证

---

### services/task_service.py (67行)
| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 7/10 | 简单 |
| 安全性 | 6/10 | ⚠️ 缺少权限检查 |
| 数据库 | 8/10 | 参数化查询 |

**问题**:
- 🔴 `update_task_status`无权限验证（第55-67行）
- 🔴 `get_today_tasks`和`get_tasks_by_date`依赖allowed_pids但调用方可能不传

---

### services/transaction_service.py (53行)
| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 简洁 |
| 安全性 | 7/10 | 依赖调用方传allowed_pids |
| 数据库 | 8/10 | 参数化查询 |

**问题**:
- ⚠️ `create_transaction`无权限检查，依赖路由层

---

### services/schedule_service.py (383行)
| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | 8/10 | 复杂但组织良好 |
| 安全性 | 8/10 | 字段白名单，权限检查 |
| 数据库 | 8/10 | 参数化查询 |

**亮点**:
- ✅ 删除操作使用软删除（status='cancelled'）
- ✅ 字段白名单验证
- ✅ 删除前验证项目权限

---

## Top 5 关键问题（按优先级排序）

### 1. 🔴 认证机制不一致 (auth.py)
**位置**: routers/auth.py 第220-371行  
**风险**: 多个接口未使用标准认证依赖，可能导致认证绕过  
**修复**: 统一使用`Depends(get_current_user)`替换手动token校验

```python
# 修复前
@router.get("/profile")
async def get_profile(token: Optional[str] = Query(None), ...):
    if not token: raise HTTPException(401, "缺少认证令牌")
    row = validate_session_token(token)

# 修复后
@router.get("/profile")
async def get_profile(user: dict = Depends(get_current_user)):
    return {"success": True, "user": get_user_by_id(user["id"])}
```

---

### 2. 🔴 Debug登录后门 (auth.py)
**位置**: routers/auth.py 第155-196行  
**风险**: 内测模式允许无密码登录，生产环境极危险  
**修复**: 生产环境完全移除该接口，或添加IP白名单+二次验证

```python
# 建议：添加环境检查
@router.post("/debug-login")
async def debug_login(...):
    if os.getenv("APP_ENV") == "production":
        raise HTTPException(403, "生产环境禁用此功能")
    # 或完全移除该路由
```

---

### 3. 🔴 密码强度不足 (auth.py)
**位置**: routers/auth.py 第102行, 320行  
**风险**: 4位密码可被暴力破解  
**修复**: 最小8位，建议包含字母+数字+特殊字符

```python
# 修复建议
import re
def validate_password(password: str) -> bool:
    if len(password) < 8:
        return False
    if not re.search(r"[A-Z]", password):
        return False
    if not re.search(r"[a-z]", password):
        return False
    if not re.search(r"\d", password):
        return False
    return True
```

---

### 4. 🟡 SQL注入风险 (dashboard.py)
**位置**: routers/dashboard.py 第73-78行  
**风险**: 动态SQL拼接增加注入面  
**修复**: 重构为完全参数化查询

```python
# 当前风险代码
stats_sql = stats_sql.replace("FROM projects p", "FROM projects p " + filter_clause...)

# 建议：在get_project_id_sql_filter中返回完整WHERE子句和参数
# 或使用ORM/查询构建器
```

---

### 5. 🟡 任务更新无权限检查 (tasks.py + task_service.py)
**位置**: routers/tasks.py 第36-42行, services/task_service.py 第55-67行  
**风险**: 用户可更新任意任务，跨项目越权  
**修复**: 添加任务所属项目权限验证

```python
# routers/tasks.py 修复
@router.put("/tasks/{task_id}")
async def api_update_task(
    task_id: int,
    status: str,
    user: dict = Depends(get_current_user),
):
    # 验证任务所属项目权限
    from services.task_service import get_task
    task = get_task(task_id)
    if task and task["project_id"]:
        if not check_project_access(user["id"], task["project_id"]):
            raise HTTPException(403, "无权操作此任务")
    return {"success": update_task_status(task_id, status)}
```

---

## 综合评分

| 文件 | 代码质量 | 安全性 | 输入校验 | 错误处理 | 数据库 | 综合 |
|------|----------|--------|----------|----------|--------|------|
| auth.py | 7 | 5 | 7 | 6 | 8 | 6.6 |
| dashboard.py | 6 | 5 | N/A | 6 | 7 | 6.0 |
| invoices.py | 8 | 8 | 7 | 7 | 8 | 7.6 |
| memos.py | 8 | 8 | 6 | 7 | 8 | 7.4 |
| schedules.py | 8 | 8 | 7 | 7 | 8 | 7.6 |
| tasks.py | 8 | 8 | 6 | 6 | 8 | 7.2 |
| transactions.py | 8 | 8 | 6 | 6 | 8 | 7.2 |
| **平均** | **7.6** | **6.6** | **6.6** | **6.6** | **7.9** | **7.0** |

---

## 修复建议优先级

### 立即修复（1周内）
1. 统一auth.py认证机制，使用`Depends(get_current_user)`
2. 移除或严格限制debug-login接口
3. 增强密码强度要求
4. 修复tasks.py权限检查缺失

### 短期修复（1个月内）
5. 重构dashboard.py动态SQL
6. 添加输入参数范围限制（limit, amount等）
7. 增强文件上传校验（魔数验证）
8. 缩短session过期时间

### 长期改进（3个月内）
9. 抽取重复代码（cookie设置、权限检查）
10. 添加统一的输入验证装饰器
11. 完善错误处理和日志记录
12. 考虑引入ORM（如SQLAlchemy）替代原生SQL

---

## 结论

项目整体代码质量中等，服务层设计较好（参数化查询、字段白名单），但路由层存在认证不一致、输入验证不足等问题。**最紧急的是修复auth.py的认证机制和移除debug-login后门**，这两个问题可能导致未授权访问。

建议建立代码审查清单，确保新代码遵循：
- ✅ 统一使用`Depends(get_current_user)`认证
- ✅ 所有写操作检查资源所有权/权限
- ✅ 输入参数使用Pydantic验证（范围、枚举、格式）
- ✅ 禁止SQL字符串拼接，使用参数化查询
- ✅ 敏感操作记录审计日志
