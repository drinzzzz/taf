# CLUES Vue3 前端代码审计报告

**项目路径**: `/www/wwwroot/clues/clues-frontend/src/`  
**审计日期**: 2026-06-07  
**框架**: Vue 3 + Vite 8 + Element Plus + Pinia + Vue Router (Hash mode)

---

## 📊 审计概览

| 类别 | 高优先级 | 中优先级 | 低优先级 | 合计 |
|------|---------|---------|---------|------|
| 问题数量 | 8 | 12 | 9 | 29 |

**审查文件总数**: 18 个 (.vue: 14, .js: 4)

---

## 🔴 高优先级问题 (High Severity)

### 1. [高危] stores/auth.js - TOKEN_KEY 使用占位符

**位置**: `src/stores/auth.js:4`

```javascript
const TOKEN_KEY='***'  // ❌ 占位符未替换
```

**问题描述**: 
- `TOKEN_KEY` 使用了 `'***'` 占位符，这会导致 localStorage 键名不安全且不规范
- 可能影响 token 的存储和读取

**修复建议**:
```javascript
const TOKEN_KEY = 'clues_admin_token'  // 或 'clues:token'
const INFO_KEY = 'clues_admin_info'
```

---

### 2. [高危] api/index.js - 响应拦截器中 Pinia store 使用不当

**位置**: `src/api/index.js:16-17, 32-33`

```javascript
// 在拦截器中直接调用 useAuthStore() 可能有问题
const authStore = useAuthStore()  // ❌ 在 app 初始化后可能无法正确获取
```

**问题描述**:
- 在 axios 拦截器中调用 `useAuthStore()` 需要在正确的 Pinia 上下文环境中
- 当前在 `main.js` 中先 `app.use(pinia)` 后设置拦截器，但拦截器是模块级别的，可能在 store 可用前执行

**修复建议**:
```javascript
// 方式 1: 从 localStorage 直接读取
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('clues_admin_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// 方式 2: 延迟初始化拦截器（在 App 中设置）
```

---

### 3. [高危] views/ResultView.vue - 反馈提交 API 调用参数错误

**位置**: `src/views/ResultView.vue:276`

```javascript
await submitFeedbackApi(assessmentId, { content: feedbackText.value })  // ❌ 参数格式错误
```

**问题描述**:
- `submitFeedback` API 定义为 `submitFeedback(id, feedback)` 接收字符串 `"like"|"dislike"`
- 但 `submitFeedbackText` 函数传递了对象 `{ content: ... }`，与 API 定义不匹配
- 后端可能无法正确解析

**修复建议**:
```javascript
// 方案 1: 修改 API 支持文本反馈
export function submitFeedbackText(id, content) {
  return apiClient.post(`/assessments/${id}/feedback`, { content })
}

// 方案 2: 统一使用对象格式
export function submitFeedback(id, data) {
  return apiClient.post(`/assessments/${id}/feedback`, data)
}
```

---

### 4. [高危] views/admin/RecordsView.vue - 删除功能未实现

**位置**: `src/views/admin/RecordsView.vue:198-208`

```javascript
const deleteRecord = async (id) => {
  await ElMessageBox.confirm('确定要删除这条记录吗？', '提示', {...})
  // TODO: Implement delete API  ❌ 只有注释，没有实际删除逻辑
  ElMessage.success('删除成功')  // 假成功
  fetchRecords()
}
```

**问题描述**:
- 删除按钮显示但实际不执行删除操作
- 用户会误以为删除成功，实际数据未变
- API 中也没有定义 `deleteRecord` 函数

**修复建议**:
```javascript
// 1. 在 api/index.js 添加删除 API
export function deleteRecord(id) {
  return apiClient.delete(`/admin/records/${id}`)
}

// 2. 在 RecordsView.vue 中实现
const deleteRecord = async (id) => {
  await ElMessageBox.confirm('确定要删除这条记录吗？', '提示', {...})
  await deleteRecordApi(id)  // 实际调用
  ElMessage.success('删除成功')
  fetchRecords()
}
```

---

### 5. [高危] router/index.js - 冗余的 DashboardView.vue

**位置**: `src/router/index.js` 和 `src/views/admin/DashboardView.vue`

**问题描述**:
- `DashboardView.vue` 是一个完整的 admin layout 组件
- 但路由中使用的是 `AdminLayout.vue` 作为 layout
- `DashboardView.vue` 从未被路由使用，是冗余代码
- 两个 layout 样式不一致（DashboardView 用浅色主题，AdminLayout 用深色主题）

**修复建议**:
- 删除 `src/views/admin/DashboardView.vue` 文件
- 或确认是否需要保留作为备用布局

---

### 6. [高危] main.js - Pinia store 初始化顺序问题

**位置**: `src/main.js:27-28`

```javascript
const authStore = useAuthStore(pinia)  // ❌ 传入 pinia 实例
authStore.syncFromStorage()
```

**问题描述**:
- Vue 3 + Pinia 最佳实践是不需要传入 pinia 实例
- `useAuthStore()` 应该在没有参数的情况下调用（当 store 已注册到 app 后）
- 当前写法虽然能工作，但不是推荐方式

**修复建议**:
```javascript
// 方式 1: 在 pinia 插件中同步
pinia.use(({ store }) => {
  if (store.$id === 'auth') {
    store.syncFromStorage()
  }
})

// 方式 2: 在 App.vue 的 onMounted 中同步
```

---

### 7. [高危] views/HomeView.vue - 数据传递依赖 sessionStorage

**位置**: `src/views/HomeView.vue:80-86` 和 `src/views/AssessmentView.vue:149-156`

**问题描述**:
- 宠物信息通过 `sessionStorage` 在页面间传递
- 如果用户刷新页面或标签页超时，数据会丢失
- 没有 fallback 机制处理数据丢失情况

**修复建议**:
```javascript
// AssessmentView.vue 中添加检查
const petInfo = JSON.parse(sessionStorage.getItem('clues_pet_info') || '{}')
if (!petInfo.pet_name) {
  ElMessage.warning('评估信息已过期，请重新开始')
  router.push('/')
  return
}
```

---

### 8. [高危] 多处缺少后端 API 对应实现

**位置**: `src/api/index.js`

**问题描述**:
以下 API 在前端调用但后端可能未实现或路径不匹配：

| 前端 API | 潜在问题 |
|---------|---------|
| `DELETE /admin/records/:id` | RecordsView 需要但未定义 |
| `GET /admin/records/:id` | `getRecordDetail` 定义了但 RecordsView 未使用 |
| `POST /assessments/:id/feedback` | 文本反馈格式不匹配 |
| `GET /personality/:species/:code` | `getPersonalityByCode` 定义了但未使用 |

**修复建议**:
- 与后端确认所有 API 路径和请求格式
- 添加 API 版本前缀如 `/api/v1/`

---

## 🟡 中优先级问题 (Medium Severity)

### 9. [中] views/admin/HomeView.vue - 图表功能未实现

**位置**: `src/views/admin/HomeView.vue:64-89`

```html
<div class="chart-placeholder">
  <el-empty description="图表数据加载中" :image-size="80" />
</div>
```

**问题描述**:
- 仪表盘显示"图表数据加载中"但实际上没有图表实现
- 没有集成任何图表库（如 ECharts）

**修复建议**:
- 安装 `echarts` 和 `vue-echarts`
- 实现趋势图和分布图

---

### 10. [中] views/NotFoundView.vue - 样式与主题不一致

**位置**: `src/views/NotFoundView.vue:22-28`

```css
.not-found-view {
  background: #f5f7fa;  /* ❌ 浅色背景，与全站深色主题不符 */
}
```

**修复建议**:
```css
.not-found-view {
  background: #1a1a2e;  /* 与全局主题一致 */
}
```

---

### 11. [中] 多处 console.error 没有用户友好提示

**位置**: 多个文件

```javascript
console.error(error)  // ❌ 只打印到控制台，用户看不到
```

**问题描述**:
- 错误只输出到控制台，用户无法感知具体问题
- 不利于问题排查

**修复建议**:
```javascript
catch (error) {
  console.error('详细错误:', error)
  ElMessage.error(`操作失败：${error.response?.data?.detail || error.message}`)
}
```

---

### 12. [中] api/index.js - 缺少请求/响应日志

**问题描述**:
- 生产环境难以追踪 API 调用问题
- 没有请求超时统一处理

**修复建议**:
```javascript
// 添加开发环境日志
if (import.meta.env.DEV) {
  apiClient.interceptors.request.use((config) => {
    console.log('[API Request]', config.method.toUpperCase(), config.url)
    return config
  })
}
```

---

### 13. [中] views/AssessmentView.vue - 题目硬编码

**位置**: `src/views/AssessmentView.vue:73-104`

**问题描述**:
- 25 道题目硬编码在组件中
- 无法动态配置或 A/B 测试
- 题目修改需要重新编译

**修复建议**:
- 将题目配置移到后端 API
- 或移到单独的配置文件 `src/config/questions.js`

---

### 14. [中] 多个 Admin 视图 - 缺少批量操作

**位置**: `RecordsView.vue`, `ActivitiesView.vue`, `AdminsView.vue`

**问题描述**:
- 表格支持单选但无批量选择功能
- 无法批量删除/导出

**修复建议**:
- 添加 `el-table` 的 `selection` 列
- 实现批量操作工具栏

---

### 15. [中] views/admin/AdminsView.vue - 密码验证逻辑问题

**位置**: `src/views/admin/AdminsView.vue:230-244`

```javascript
const validatePassword = (rule, value, callback) => {
  if (!isEdit.value && value !== form.confirmPassword) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}
```

**问题描述**:
- 验证器依赖 `form.confirmPassword`，但该值可能还未更新
- 应该使用 `validator` 的第三个参数获取表单值

**修复建议**:
```javascript
// 使用 Element Plus 推荐的跨字段验证方式
const validateConfirmPassword = (rule, value, callback, source, options) => {
  // 通过 formRef 获取最新值
}
```

---

### 16. [中] 样式重复定义

**位置**: `App.vue`, `AdminLayout.vue`, 各 View 组件

**问题描述**:
- Element Plus 深色主题样式在多个文件中重复定义
- 不利于维护和统一修改

**修复建议**:
- 创建 `src/styles/element-dark.css` 统一存放
- 在 `main.js` 中一次性引入

---

### 17. [中] views/admin/DailyReportView.vue - 发送记录无数据

**位置**: `src/views/admin/DailyReportView.vue:146-148`

```javascript
const sendRecords = ref([
  // Mock data for now  ❌ 空数组，无实际数据
])
```

**修复建议**:
- 添加获取发送记录的 API
- 实现数据加载

---

### 18. [中] 缺少路由级权限控制

**位置**: `src/router/index.js`

**问题描述**:
- 只有 `requiresAuth` 检查是否登录
- 没有基于角色的权限控制（RBAC）
- 所有登录管理员可访问所有页面

**修复建议**:
```javascript
// 添加角色元数据
{
  path: 'admins',
  meta: { requiresAuth: true, requiresRole: ['super_admin'] }
}

// 在路由守卫中检查
if (meta.requiresRole && !meta.requiresRole.includes(authStore.adminInfo?.role)) {
  next('/admin')  // 重定向到无权限页
}
```

---

### 19. [中] views/ResultView.vue - 雷达图标签与维度不匹配

**位置**: `src/views/ResultView.vue:74-78`

```javascript
// 代码中使用：社交性、探索性、配合度、情绪性、活力
// 图表显示：外向性、神经质、宜人性、尽责性、开放性
```

**问题描述**:
- 评估题目使用的维度名称与结果页雷达图标签不一致
- 可能导致用户困惑

**修复建议**:
- 统一维度命名（建议用大五人格标准名称）
- 或确保题目维度与图表标签对应

---

### 20. [中] 缺少全局错误边界

**问题描述**:
- 没有 Vue 3 的 `errorCaptured` 全局处理
- 组件错误可能导致整个应用崩溃

**修复建议**:
```javascript
// main.js
app.config.errorHandler = (err, instance, info) => {
  console.error('Global error:', err, info)
  // 上报错误监控服务
}
```

---

## 🟢 低优先级问题 (Low Severity)

### 21. [低] components/HelloWorld.vue - 未使用的默认模板

**位置**: `src/components/HelloWorld.vue`

**问题描述**:
- Vite 默认模板组件，项目中未使用
- 应删除以保持代码整洁

**修复建议**: 删除该文件

---

### 22. [低] 缺少组件文档注释

**问题描述**:
- 组件缺少 JSDoc 风格注释
- 不利于团队协作和维护

**修复建议**:
```javascript
/**
 * 评估结果展示组件
 * @description 展示宠物性格评估报告，含雷达图和维度分析
 */
```

---

### 23. [低] 魔法数字

**位置**: 多处

```javascript
const radius = 100  // ❌ 魔法数字
const angles = [-90, 18, 90, 162, 234]
```

**修复建议**:
```javascript
const CHART_CONFIG = {
  radius: 100,
  center: { x: 150, y: 150 },
  dimensions: 5
}
```

---

### 24. [低] 可访问性 (A11y) 问题

**问题描述**:
- 按钮缺少 `aria-label`
- 图标缺少 `role="img"` 和描述

**修复建议**:
```html
<el-button aria-label="关闭对话框" @click="...">
<el-icon role="img" aria-label="用户图标"><User /></el-icon>
```

---

### 25. [低] 未使用的导入

**位置**: 多个文件

```javascript
import { ref, computed, onMounted } from 'vue'
// 可能只使用了 ref
```

**修复建议**: 清理未使用的导入

---

### 26. [低] 硬编码的日期格式

**位置**: `RecordsView.vue`, `ActivitiesView.vue`

```javascript
link.download = `评估记录_${new Date().toISOString().split('T')[0]}.xlsx`
```

**修复建议**:
```javascript
// 使用工具函数
import { formatDate } from '@/utils/date'
link.download = `评估记录_${formatDate(new Date(), 'YYYY-MM-DD')}.xlsx`
```

---

### 27. [低] 缺少加载骨架屏

**问题描述**:
- 使用 `v-loading` 但无骨架屏
- 加载体验不够流畅

**修复建议**: 使用 Element Plus 的 `el-skeleton` 组件

---

### 28. [低] 分页组件可优化

**位置**: 多个 Admin 视图

**问题描述**:
- 分页组件重复代码多
- 可抽取为可复用组件

**修复建议**: 创建 `src/components/TablePagination.vue`

---

### 29. [低] 环境变量未使用

**问题描述**:
- API baseURL 硬编码为 `/api`
- 未使用 `.env` 配置文件

**修复建议**:
```javascript
// .env
VITE_API_BASE_URL=/api

// api/index.js
baseURL: import.meta.env.VITE_API_BASE_URL || '/api'
```

---

## ✅ 代码优点

1. **Vue 3 Composition API**: 正确使用 `<script setup>` 语法
2. **响应式数据**: 合理使用 `ref`, `reactive`, `computed`
3. **Element Plus 集成**: 组件使用规范，深色主题统一
4. **路由守卫**: 实现了基础的认证检查
5. **Pinia 状态管理**: 结构清晰，有持久化处理
6. **API 封装**: 统一的 axios 实例和拦截器
7. **表单验证**: 使用了 Element Plus 的表单验证规则

---

## 📋 修复优先级建议

### 立即修复 (P0)
1. `TOKEN_KEY` 占位符替换
2. RecordsView 删除功能实现
3. ResultView 反馈提交参数修复
4. API 拦截器 Pinia 使用问题

### 短期修复 (P1)
5. 图表功能实现
6. 404 页面主题统一
7. 错误处理优化
8. 删除冗余 DashboardView

### 中期优化 (P2)
9. 题目配置外部化
10. 批量操作功能
11. 角色权限控制
12. 样式统一管理

---

## 🔧 建议新增文件

```
src/
├── config/
│   └── questions.js          # 评估题目配置
├── utils/
│   ├── date.js              # 日期工具函数
│   └── validators.js        # 自定义验证器
├── styles/
│   └── element-dark.css     # Element Plus 深色主题
├── components/
│   └── TablePagination.vue  # 可复用分页组件
└── hooks/
    └── useTable.js          # 表格通用逻辑 hooks
```

---

**审计完成** ✅
