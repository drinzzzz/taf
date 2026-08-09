# CLUES 宠物性格测试系统 - 完整架构审计报告

**审计时间**: 2026-06-07  
**项目路径**: `/www/wwwroot/clues/clues_website/`  
**系统版本**: v2.1 (FastAPI + Flask 双架构)  
**数据库**: MySQL 8.0.45 (已从 5.7 升级)

---

## 一、目录结构总览

```
/www/wwwroot/clues/clues_website/
├── backend/                          # FastAPI 后端 (v2.0 API)
│   ├── main.py                       # FastAPI 应用入口
│   ├── config.py                     # 配置管理 (环境变量/.env)
│   ├── database.py                   # SQLAlchemy 连接池
│   ├── create_tables.py              # 表创建脚本
│   ├── models/
│   │   └── models.py                 # SQLAlchemy ORM 模型
│   ├── routers/
│   │   ├── health.py                 # 健康检查 API
│   │   ├── auth.py                   # JWT 认证
│   │   ├── assessments.py            # 评估 CRUD
│   │   ├── personality.py            # 性格类型查询
│   │   ├── dependencies.py           # 依赖注入 (权限/角色)
│   │   └── admin/
│   │       ├── dashboard.py          # 仪表盘统计
│   │       ├── records.py            # 记录管理
│   │       ├── activities.py         # 活动管理
│   │       ├── admins.py             # 管理员管理
│   │       ├── export.py             # 数据导出 (CSV/Excel)
│   │       └── daily_report.py       # 日报配置
│   ├── services/
│   │   └── personality.py            # CLUE 算法核心服务
│   ├── schemas/
│   │   └── __init__.py               # Pydantic 请求/响应模型
│   └── migrations/
│       └── v2.1_permissions.sql      # 权限扩展迁移
│
├── app.py                            # Flask 主应用 (旧版，仍在使用)
├── admin.py                          # Flask 后台管理蓝本
├── cron_daily_report.py              # 晚报生成脚本 (FastAPI 版)
├── services/daily_report.py          # 晚报服务 (Flask 版)
├── models.py                         # Flask SQLAlchemy 模型
├── forms.py                          # WTForms 表单定义
├── generate_descriptions.py          # 性格描述生成工具
├── cat_personality.py                # 猫性格系统 (旧)
├── dog_personality.py                # 狗性格系统 (旧)
├── data/
│   ├── cat/                          # 猫性格描述 MD 文件 (32 种)
│   └── dog/                          # 狗性格描述 MD 文件 (32 种)
├── templates/                        # Jinja2 模板 (Flask)
│   ├── admin_*.html                  # 后台管理页面 (15+)
│   ├── index.html, quiz.html, result.html  # 前端页面
│   └── base.html, error.html, maintenance.html
├── static/
│   ├── css/                          # 样式表
│   ├── js/                           # JavaScript
│   └── uploads/                      # 用户上传头像 (200+ 文件)
├── requirements.txt                  # Python 依赖 (Flask 系)
├── gunicorn_conf.py                  # Gunicorn 配置
└── uwsgi.ini                         # uWSGI 配置 (备用)
```

---

## 二、数据库表结构

### 2.1 核心表

| 表名 | 说明 | 关键字段 |
|------|------|----------|
| `pet_assessment` | 宠物评估记录 | id, pet_name, pet_species, pet_breed, pet_age, scores_json, clue_code, clue_role, clue_slogan, channel, activity_key, like_count, dislike_count, has_x, created_at |
| `admins` | 管理员账户 | id, username, password_hash (bcrypt), role (super_admin/admin/viewer/partner), nickname, email, weixin_id, is_active |
| `activities` | 活动管理 | id, name, activity_key (唯一), activity_type (public/partner/internal), status (draft/active/finished/closed), start_time, end_time, created_by |
| `activity_assessments` | 活动 - 评估关联 | activity_id, assessment_id (多对多) |
| `activity_permissions` | 活动权限 | admin_id, activity_id, permission_type (full/view_data/export_data), allowed_activities |
| `daily_report_config` | 日报配置 | enabled, report_time, email_recipients, weixin_recipients, last_sent_at |
| `personality_types` | 性格类型 (待迁移) | species, clue_code, pathway, sequence, nickname, slogan, description_md |

### 2.2 角色权限体系

```
角色层级: super_admin (3) > admin (2) > viewer/partner (1)

权限类型:
- full: 完整权限 (查看 + 编辑 + 导出)
- view_data: 仅查看数据
- export_data: 查看 + 导出

权限控制:
- super_admin: 访问所有活动/数据
- admin: 默认访问 public 活动，可通过 activity_permissions 扩展
- viewer/partner: 仅访问被授权的活动
```

---

## 三、API 端点清单

### 3.1 公共 API (FastAPI)

| 端点 | 方法 | 认证 | 说明 |
|------|------|------|------|
| `/api/health` | GET | 无 | 健康检查 |
| `/api/auth/login` | POST | 无 | 管理员登录 (JWT) |
| `/api/auth/me` | GET | JWT | 获取当前管理员信息 |
| `/api/assessments` | POST | 无 | 创建评估 |
| `/api/assessments/{id}` | GET | 无 | 获取评估详情 |
| `/api/assessments/{id}/feedback` | POST | 无 | 提交反馈 (点赞/质疑) |
| `/api/personality/{species}/{code}` | GET | 无 | 获取性格描述 |

### 3.2 后台管理 API (FastAPI)

| 端点 | 方法 | 权限 | 说明 |
|------|------|------|------|
| `/api/admin/dashboard` | GET | admin+ | 仪表盘统计 |
| `/api/admin/records` | GET | admin+ | 评估记录分页查询 |
| `/api/admin/activities/` | GET/POST | admin+ | 活动列表/创建 |
| `/api/admin/activities/{id}` | GET/PUT/DELETE | admin+/super_admin | 活动详情/更新/删除 |
| `/api/admin/activities/{id}/status` | PATCH | admin+ | 更新活动状态 |
| `/api/admin/admins` | GET/POST | super_admin | 管理员列表/创建 |
| `/api/admin/admins/{id}` | PUT | super_admin | 更新管理员 |
| `/api/admin/admins/{id}/permissions` | GET/POST | super_admin | 活动权限管理 |
| `/api/admin/export` | GET | admin+ | 导出 CSV/Excel |
| `/api/admin/daily-report/config` | GET/PUT | admin+ | 日报配置 |

### 3.3 Flask 后台页面 (旧版，仍在使用)

| 路由 | 说明 |
|------|------|
| `/admin/login` | 后台登录 |
| `/admin/` | 仪表盘 |
| `/admin/records` | 记录管理 |
| `/admin/activities` | 活动管理 |
| `/admin/admins` | 管理员管理 |
| `/admin/export` | 数据导出 |

---

## 四、关键模块详解

### 4.1 认证系统 (FastAPI JWT)

**文件**: `backend/routers/auth.py`, `backend/routers/dependencies.py`

```python
# 登录流程
1. POST /api/auth/login → 验证用户名密码 (bcrypt)
2. IP 限速：5 次失败锁定 5 分钟
3. 成功 → 返回 JWT token (60 分钟有效)
4. 后续请求带 Authorization: Bearer <token>

# Token 内容
{
    "sub": username,
    "admin_id": id,
    "role": role,
    "exp": expiration
}

# 角色检查装饰器
@router.post('/admins', dependencies=[Depends(require_super_admin)])
```

### 4.2 CLUE 算法核心

**文件**: `backend/services/personality.py`

```python
# 5 个维度，每个维度 5 题 (1-5 分)
维度映射:
- 社交倾向 (Social): E(热情) vs I(独立)
- 探索能级 (Explore): A(冒险) vs C(谨慎)
- 配合状态 (Cooperate): O(服从) vs P(固执)
- 情绪特征 (Emotion): R(镇定) vs S(敏感)
- 活力水平 (Vitality): V(活力) vs Q(安静)

# 计算逻辑
1. 每个维度 5 题，统计≥4 分 (倾向高) 和≤2 分 (倾向低) 的数量
2. 投票决定字母，平局时看总分 (≥15 分倾向高)
3. 生成 5 字母代码 (如 E-A-O-R-V)
4. 查表获取角色名、口号、途径信息

# 性格类型数量
- 狗: 32 种 (4 途径 × 8 序列)
- 猫: 32 种 (4 途径 × 8 序列)
```

### 4.3 活动管理系统

**文件**: `backend/routers/admin/activities.py`, `backend/models/models.py`

```python
# 活动类型
- public: 公开活动，所有 admin 可访问
- partner: 合作方活动，需授权
- internal: 内部活动

# 活动状态
- draft: 草稿
- active: 进行中
- finished: 已结束
- closed: 已关闭

# 评估关联方式
1. activity_key 字段直接关联 (推荐)
2. activity_assessments 关联表 (多对多)
```

### 4.4 数据导出功能

**文件**: `backend/routers/admin/export.py`

```python
# 导出格式
- CSV: io.StringIO + csv.writer
- Excel: openpyxl (降级到 CSV 如果未安装)

# 导出选项
- format: csv|xlsx
- activity_key: 活动筛选
- date_from/date_to: 日期范围
- species: dog|cat
- summary: 统计摘要模式

# 安全措施
- CSV 注入防护 (csv_safe 函数)
- 活动权限过滤
```

### 4.5 日报系统

**文件**: `cron_daily_report.py`, `services/daily_report.py`

```python
# 晚报内容
- 当日新增 (狗/猫分布)
- 累计总数
- 性格分布 Top5
- 点赞/质疑统计
- 渠道分布
- 异常记录 (含 X)

# 推送方式
- 邮件: SMTP (需配置 SMTP_HOST/USER/PASS)
- 微信: 预留 weixin_recipients 字段 (未实现)

# 定时任务
- cron_daily_report.py --send
- 推荐每天 20:00 执行
```

---

## 五、已有功能基座清单

### 5.1 已完成功能 ✅

| 模块 | 状态 | 说明 |
|------|------|------|
| 用户评估 | ✅ | 25 题测试，CLUE 算法计算，结果保存 |
| 性格类型系统 | ✅ | 猫/狗各 32 种类型，MD 描述文件 |
| 管理员认证 | ✅ | JWT + bcrypt，IP 限速 |
| 角色权限 | ✅ | super_admin/admin/viewer/partner |
| 活动管理 | ✅ | CRUD + 状态流转 |
| 数据导出 | ✅ | CSV/Excel，带权限过滤 |
| 仪表盘 | ✅ | 统计卡片 + Top10 + 最新记录 |
| 日报生成 | ✅ | HTML+ 文本，邮件发送 |
| 维护模式 | ✅ | JSON 配置文件，中间件拦截 |
| 反馈系统 | ✅ | 点赞/质疑计数 |
| 渠道追踪 | ✅ | activity_key/channel 字段 |
| 异常处理 | ✅ | 全局异常处理器，用户友好提示 |
| 请求日志 | ✅ | 中间件记录所有请求 |
| 速率限制 | ✅ | SlowAPI 60 次/分钟 |
| CORS | ✅ | 可配置来源列表 |
| 文件上传 | ✅ | 头像上传，类型校验 |

### 5.2 待增强功能 ⚠️

| 模块 | 现状 | 建议 |
|------|------|------|
| 微信推送 | ⚠️ 仅预留字段 | 实现微信模板消息/企业微信 |
| 性格类型数据库化 | ⚠️ 仍用 MD 文件 | 迁移到 personality_types 表 |
| 前端 SPA | ⚠️ 无独立前端 | 开发 Vue/React 前端 |
| 用户系统 | ❌ 无 | 添加普通用户注册/登录 |
| 评估历史 | ⚠️ 仅后台查看 | 用户个人中心查看历史 |
| 分享功能 | ❌ 无 | 生成分享海报/链接 |
| 数据可视化 | ⚠️ 基础表格 | ECharts 图表 |
| API 文档 | ✅ Swagger | 完善文档和示例 |
| 测试用例 | ❌ 无 | pytest 单元测试 |
| CI/CD | ❌ 无 | GitHub Actions 部署 |

---

## 六、安全与容错机制

### 6.1 安全措施

```python
# 认证安全
- JWT token 60 分钟过期
- bcrypt 密码哈希 (12 轮)
- 登录失败 5 次锁定 5 分钟

# 数据安全
- CSV 注入防护
- SQL 注入防护 (SQLAlchemy ORM)
- XSS 防护 (bleach 清洗 HTML)

# 访问控制
- 角色权限检查
- 活动权限隔离
- CORS 白名单

# 请求限制
- 请求体大小限制 (10MB)
- 速率限制 (60 次/分钟)
```

### 6.2 容错机制

```python
# 数据库
- 连接池预检测 (pool_pre_ping)
- 断连自动重连
- 事务自动回滚

# 异常处理
- 全局异常处理器
- 数据库异常友好提示
- 维护模式中间件

# 日志
- 请求日志中间件
- 错误日志记录
- 操作审计日志 (管理员操作)
```

---

## 七、技术栈总结

| 类别 | 技术 |
|------|------|
| 后端框架 | FastAPI (v2.0 API) + Flask (旧版) |
| 数据库 | MySQL 8.0.45 + SQLAlchemy 2.0 |
| ORM | SQLAlchemy (FastAPI) + Flask-SQLAlchemy |
| 认证 | JWT (python-jose) + bcrypt (passlib) |
| 表单验证 | Pydantic (FastAPI) + WTForms (Flask) |
| 模板 | Jinja2 |
| 服务器 | Gunicorn (4 workers × 2 threads) |
| 部署 | uWSGI (备用) |
| 定时任务 | cron + Python 脚本 |
| 邮件 | SMTP (smtplib) |

---

## 八、建议与改进方向

### 8.1 短期优化 (P0-P1)

1. **统一后端架构**: 逐步迁移 Flask 功能到 FastAPI
2. **完善微信推送**: 接入企业微信/微信公众号 API
3. **性格类型数据库化**: 将 MD 文件迁移到 personality_types 表
4. **添加单元测试**: pytest + pytest-asyncio

### 8.2 中期增强 (P2)

1. **开发独立前端**: Vue 3 + Vite + Element Plus
2. **用户系统**: 普通用户注册/登录/个人中心
3. **分享功能**: 生成结果海报，微信分享
4. **数据可视化**: ECharts 仪表盘

### 8.3 长期规划 (P3)

1. **多语言支持**: i18n 国际化
2. **API 版本管理**: /api/v1/, /api/v2/
3. **微服务拆分**: 评估服务、用户服务、通知服务
4. **容器化部署**: Docker + Kubernetes

---

## 九、关键文件索引

| 文件 | 行数 | 说明 |
|------|------|------|
| `backend/main.py` | 178 | FastAPI 入口，中间件注册 |
| `backend/config.py` | 91 | 配置管理 |
| `backend/database.py` | 64 | 数据库连接池 |
| `backend/models/models.py` | 229 | ORM 模型定义 |
| `backend/services/personality.py` | 234 | CLUE 算法核心 |
| `backend/routers/auth.py` | 135 | JWT 认证 |
| `backend/routers/assessments.py` | 177 | 评估 CRUD |
| `backend/routers/dependencies.py` | 137 | 权限依赖注入 |
| `admin.py` | 649 | Flask 后台管理 |
| `cron_daily_report.py` | 284 | 晚报生成脚本 |
| `services/daily_report.py` | 221 | 晚报服务 (Flask) |

---

**审计完成时间**: 2026-06-07 10:55 AM  
**审计人**: Hermes Agent
