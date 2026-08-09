# ProjectMate 系统 API 盘点报告

## 总览

- **后端路由文件**: 37 个 (routers/ 下)
- **前缀分组**: 12 个带独立 prefix，其余统一用 `/api`
- **静态前端 JS 文件**: 13 个
- **前端加载方式**: dashboard.html 一次性加载所有 JS 文件

---

## 一、API 端点完整映射表

### 基础说明

- 前端通过 `ag(path)` 或 `apPut/apPost/apDelete` 调用时，实际发送到 `/api` + path
- 即 `ag('/projects')` = `GET /api/projects?token=xxx`
- `apPut('/projects/1', data)` = `PUT /api/projects/1`

### 路由 → JS 文件对应关系

| # | 路由文件 | prefix | 端点数 | 前端 JS 实现 | 实现状态 |
|---|---------|--------|--------|-------------|---------|
| 1 | auth.py | `/api/auth` | 9 | core.js + dashboard.js | ✅ 完善 |
| 2 | projects.py | `/api` | 6 | dashboard.js + project-views.js + wechat-contacts.js | ✅ 完善 |
| 3 | tasks.py | `/api` | 4 | dashboard.js | ✅ 完善 |
| 4 | workorders.py | `/api` | 4 | dashboard.js + project-views.js + wechat-contacts.js | ✅ 完善 |
| 5 | transactions.py | `/api` | 2 | dashboard.js + wechat-contacts.js | ✅ 完善 |
| 6 | meetings.py | `/api` | 2 | dashboard.js + wechat-contacts.js | ✅ 完善 |
| 7 | invoices.py | `/api` | 6 | dashboard.js | ✅ 完善 |
| 8 | contacts.py | `/api` | 2 | dashboard.js | ✅ 完善 |
| 9 | crm.py | `/api` | 12 | crm.js | ✅ 完善 |
| 10 | schedules.py | `/api` | 10 | schedule.js | ✅ 完善 |
| 11 | suppliers.py | `/api` | 14 | subcontractor.js | ✅ 完善 |
| 12 | contract_documents.py | `/api` | 20 | contracts.js | ✅ 完善 |
| 13 | contract_generate.py | `/api` | 3 | contracts.js | ✅ 完善 |
| 14 | business_trips.py | `/api` | 6 | trips.js | ✅ 完善 |
| 15 | notifications_api.py | `/api/notifications` | 6 | notifications.js | ✅ 完善 |
| 16 | knowledge_base_api.py | `/api/knowledge-base` | 5 | knowledge_base.js | ✅ 完善 |
| 17 | quotations.py | `/api` | 5 | quotation.js | ✅ 完善 |
| 18 | files_api.py | `/api` | 5 | project-views.js | ✅ 完善 |
| 19 | data_import_api.py | `/api` | 2 | data_import.js | ✅ 完善 |
| 20 | contacts_manage_api.py | `/api/contacts-manage` | 6 | wechat-contacts.js | ✅ 完善 |
| 21 | project_access.py | `/api/access` | 7 | wechat-contacts.js | ✅ 完善 |
| 22 | audit_logs_api.py | `/api/audit-logs` | 2 | audit-logs.js | ✅ 完善 |
| 23 | milestones.py | `/api` | 3 | project-features.js(部分) | ⚠️ 端点到前端路径不一致 |
| 24 | deliverables.py | `/api` | 3 | project-features.js | ✅ 完善 |
| 25 | contracts.py | `/api` | 3 | schedule.js + project-features.js | ✅ 完善 |
| 26 | dashboard.py | `/api` | 1 | dashboard.js | ✅ 完善 |
| 27 | export_api.py | `/api` | 3 | dashboard.js (window.open) | ✅ 完善 |
| 28 | project_export.py | `/api` | 1 | dashboard.js + project-views.js | ✅ 完善 |
| 29 | frontend_logs.py | `/api/logs` | 2 | core.js + wechat-contacts.js | ✅ 完善 |
| 30 | nav_config.py | `/api/nav` | 2 | core.js | ✅ 完善 |
| 31 | platform_admin_api.py | `/api/platform` | 4 | admin.html (内联) | ✅ 完善 |
| 32 | tenant_api.py | `/api/tenant` | 3 | 无前端页面 | ❌ 未实现 |
| 33 | conversations.py | `/api` | 8 | **无前端页面** | ❌ 完全缺失 |
| 34 | classifications.py | `/api` | 1 | **无前端页面** | ❌ 完全缺失 |
| 35 | stakeholders.py | `/api` | 5 | **无前端页面** | ❌ 完全缺失 |
| 36 | nutstore.py | `/api` | 4 | **无前端页面** | ❌ 完全缺失 |
| 37 | travel.py | `/api` | 6 | **无前端页面** | ❌ 完全缺失 |

---

## 二、严重缺失前端界面的 API 模块

以下是完全没有前端实现的后端模块：

### 1. `conversations.py` — 会话/对话管理 (8 端点)
| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/conversations/{user_id}` | GET | 获取用户对话 |
| `/api/conversations/{user_id}/context` | GET | 对话上下文 |
| `/api/conversations/{user_id}/summary` | GET/POST | 对话摘要 |
| `/api/conversations/tags` | GET | 对话标签 |
| `/api/system/state/{key}` | GET/PUT | 系统状态 |
| `/api/system/events` | GET | 系统事件 |

### 2. `classifications.py` — 分类管理 (1 端点)
| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/classifications` | GET | 获取分类列表 |

### 3. `stakeholders.py` — 项目干系人管理 (5 端点)
| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/stakeholders` | GET | 干系人列表 |
| `/api/stakeholders/{id}` | GET/PUT | 干系人详情/更新 |
| `/api/stakeholders` | POST | 创建干系人 |
| `/api/projects/{project_id}/stakeholders` | GET/POST | 项目干系人 |

### 4. `nutstore.py` — 坚果云集成 (4 端点)
| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/nutstore/links` | GET | 链接列表 |
| `/api/nutstore/scan` | POST | 扫描 |
| `/api/nutstore/project/{project_id}` | GET | 项目文件 |
| `/api/nutstore/summary` | GET | 汇总 |

### 5. `travel.py` — 差旅管理 (6 端点)
> 注意：`business_trips.py` (出差) 有完善前端 trips.js，而 `travel.py` (差旅) 独立，完全不同
| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/travels` | GET/POST | 差旅列表/创建 |
| `/api/travels/{id}` | GET/PUT/DELETE | 差旅 CRUD |
| `/api/projects/{project_id}/travel-summary` | GET | 项目差旅汇总 |

### 6. `tenant_api.py` — 租户 API (3 端点)
| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/tenant/register` | POST | 租户注册 |
| `/api/tenant/list` | GET | 租户列表 |
| `/api/tenant/{slug}/status` | GET | 租户状态 |

> 说明：`/api/platform` 的管理后台 admin.html 有界面，但 `/api/tenant` 是租户侧自治接口，没有前端

---

## 三、前端-后端路径不匹配问题 (BUG)

| 前端调用路径 | 实际后端路径 | 影响 |
|-------------|------------|------|
| `ag('/milestones/project/'+pid)` | `/api/projects/{project_id}/milestones` | 项目详情页的里程碑数据加载失败 |
| `ag('/business_trips/summary?project_id='+pid)` | `/api/projects/{project_id}/trip-summary` | 项目详情页的出差汇总数据加载失败 |

---

## 四、已完善实现的模块

| 模块 | 路由文件 | 前端文件 | 说明 |
|------|---------|---------|------|
| 📊 总览看板 | dashboard.py | dashboard.js | KPI + 图表 |
| 📂 项目管理 | projects.py | dashboard.js, project-views.js | CRUD + 详情 |
| 🔁 售前管道 | projects.py | dashboard.js | 线索管道 |
| 🔧 工单管理 | workorders.py | dashboard.js | 列表+状态变更 |
| 💰 财务管理 | transactions.py, invoices.py | dashboard.js | 收支+发票 |
| 📅 会议管理 | meetings.py | dashboard.js | 列表+详情 |
| ✅ 任务管理 | tasks.py | dashboard.js | 按日期筛选 |
| 👥 联系人 | contacts.py | dashboard.js | 项目联系人 |
| 📋 报价 | quotations.py | quotation.js | 版本管理 |
| 📄 合同 | contract_documents.py | contracts.js | 完整合同管理 |
| 🤝 CRM | crm.py | crm.js | 公司+干系人 |
| 📅 工期 | schedules.py | schedule.js | Vue组件 |
| 🏗️ 分包商 | suppliers.py | subcontractor.js | 供应商+分包 |
| 🚄 出差 | business_trips.py | trips.js | 出差管理 |
| 🔔 通知 | notifications_api.py | notifications.js | 通知面板 |
| 📚 知识库 | knowledge_base_api.py | knowledge_base.js | 知识条目 |
| 📥 导入导出 | data_import_api.py | data_import.js | 模板+导入 |
| 📁 文件管理 | files_api.py | project-views.js | 上传下载 |
| 📋 审计日志 | audit_logs_api.py | audit-logs.js | 日志查看 |
| 🛡️ 权限管理 | project_access.py | wechat-contacts.js | 访问控制 |
| 🤖 微信联系人 | contacts_manage_api.py | wechat-contacts.js | 联系人管理 |
| 👤 认证用户管理 | auth.py | core.js + wechat-contacts.js | 登录/注册/用户 |
| ⚙️ 导航配置 | nav_config.py | core.js | 侧边栏编辑 |
| 🏢 平台管理 | platform_admin_api.py | admin.html | 租户管理 |
| 📋 交付物 | deliverables.py | project-features.js | 项目交付物 |
| 🗂️ 里程碑 | milestones.py | project-features.js | ⚠️ 路径不匹配 |

---

## 五、总结

### 已完成前端界面的功能模块 (25/37 = 68%)
dashboard.js + 12 个独立 JS 文件覆盖了大部分核心业务功能。

### 严重缺失前端的模块 (6/37 = 16%)
1. **conversations.py** — 会话管理 (8 个 API) — 最严重缺失
2. **classifications.py** — 分类管理 (1 个 API)
3. **stakeholders.py** — 干系人管理 (5 个 API)
4. **nutstore.py** — 坚果云集成 (4 个 API)
5. **travel.py** — 差旅管理 (6 个 API) — 注意与 business_trips 不同
6. **tenant_api.py** — 租户自治 API (3 个 API)

### 前端-后端路径不匹配 (2 处)
1. `/milestones/project/{id}` → 应改为 `/projects/{project_id}/milestones`
2. `/business_trips/summary` → 应改为 `/projects/{project_id}/trip-summary`

### 备注
- dashboard.js (64KB, 1177行) 是核心前端，处理 8 个页面（总览、项目、管道、工单、财务、会议、任务、联系人）
- 除 dashboard.js 外另有 12 个独立 JS 文件分担其他功能
- admin.html 是纯内联 JS 的管理后台（平台管理）
