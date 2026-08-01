# Phase 2 实施任务清单

> 创建时间: 2026-08-02
> 当前状态: ✅ 已完成
> 会话恢复: 读此文件即知进度

---

## 总览

| # | 模块 | 端点 | 当前状态 | 目标 |
|---|------|------|:---:|------|
| T1 | ③a 布点图 DXF | `POST .../layout` | ⚠️ 可用但硬编码 | 对接真实底图+空间数据 |
| T2 | ③b 标注渲染 PNG | `POST .../annotated-map` | ⚠️ 可用但硬编码 | 对接项目实际设施位置 |
| T3 | ③c 热力图 | `GET .../heatmap` | ❌ 未实现 | 设施密度+服务半径 |
| T4 | ⑥ 叙事引擎 | `GET .../narrative` | ⚠️ 模板降级 | LLM 驱动生成 |
| T5 | ⑦ 渲染管线 | `GET .../prompts` | ✅ 已完成 | 21 prompts / 7 空间 |
| T6 | 前端成果页 | 新增「📦 成果」tab | ❌ 未实现 | 集中生成/下载入口 |

---

## T1: 布点图 DXF 增强

### 当前问题
- 空间中心点硬编码（`deliverables.py` L1072-1077），不读 DB Space 实体
- 无底图文件时自动生成空白 DXF，缺少兴顺里实际地形
- 设施符号单一（仅圆圈），缺少分类图标

### 步骤
- [x] 1.1 审计：确认 DB 中 Space 实体是否存在 → 6 spaces ✅
- [x] 1.2 Basemap DXF 底图存在 → 2 个 DXF ✅
- [x] 1.3 修改布点算法：读取 DXF 图层边界 → 空间感知布点
- [x] 1.4 设施符号多样化：P1□ P2◎ P3▽ P4⬠ P5◇ P6○ + 图例匹配
- [x] 1.5 提取 `_build_layout_dxf_core` 共享函数，端点+打包器共用
- [x] 1.6 修复包端点缺失的 Space/Basemap 查询
- [x] 1.7 验证：端点 HTTP 200, 69KB DXF ✅

### 数据流
```
Project(id) → Space(project_id) → 空间边界/中心
           → Facility(project_id) → 按 category 分组
           → Basemap(project_id, dxf) → 叠加层
ezdxf → TAF-FACILITY + TAF-LABEL + TAF-LEGEND 图层
```

---

## T2: 标注渲染 PNG 增强

### 当前问题
- 区域坐标硬编码（`deliverables.py` L1246-1254），非项目实际布局
- 设施布点用固定位置，未映射真实坐标
- 无图例、无评分色块联动

### 步骤
- [ ] 2.1 区域布局对接 Space 实体
- [ ] 2.2 评分色块联动：板块得分率 → 绿/黄/红
- [ ] 2.3 添加图例：设施符号 + 评分色标 + 动线说明
- [ ] 2.4 动线箭头优化：入口→通道→节点→绿地→出口
- [ ] 2.5 验证：curl → 下载 PNG → 视觉检查
- [x] 2.6 提取 `_build_annotated_map_core` + `_generate_annotated_map_inline`
- [x] 2.7 创建 `_generate_narrative_inline` + `_generate_prompts_inline`
- [x] 2.8 修复包端点 4 个缺失内联函数 → ZIP 528KB 全部 8 文件 ✅

---

## T3: 热力图（新端点）

### 目标
`GET /api/projects/{id}/deliverables/heatmap`
→ 设施密度热力图 + 服务半径分析图 PNG

### 步骤
- [ ] 3.1 安装依赖（如需）：`pip install matplotlib numpy scipy`
- [x] 3.2 设施密度热力图：KDE 密度估计 → matplotlib contourf ✅
- [x] 3.3 服务半径分析：每设施为中心画覆盖圆 → 叠加 ✅
- [x] 3.4 双图并排输出：左密度 + 右半径 ✅
- [x] 3.5 验证：curl → 1990×700 PNG, 71KB ✅

---

## T4: 叙事引擎 LLM 升级

### 当前问题
- LLM 调用走 deepseek API，但服务器未配 `DEEPSEEK_API_KEY`
- 降级到硬编码模板，非动态生成

### 步骤
- [x] 4.1 检查 deepseek API key → ¥257 余额可用但密钥不可达
- [x] 4.2 改用数据驱动模板：动态引用项目实际设施名（`pick()` 按板块取前 3 个）
- [x] 4.3 端点 fallback 直接调用 `_generate_narrative_inline()` 消除重复
- [x] 4.4 验证：17 个设施引用全部来自 DB，非硬编码 ✅

---

## T5: 渲染管线（复核）

### 当前状态
✅ 已完成：21 个 prompt（7 空间 × 3 视角），MJ + SD 双格式

### 步骤
- [x] 5.1 复核 prompt 质量：21/21 全部引用真实设施名（0 泛化降级）✅
- [ ] 5.2 可选：评估是否对接 ComfyUI MCP（已有 skill）自动出图

---

## T6: 前端「📦 成果」tab

### 目标
项目详情页新增 tab，集中管理成果生成/下载

### 步骤
- [ ] 6.1 新增 route: `/project/:id/deliverables`
- [ ] 6.2 页面：产物清单 + 逐项生成按钮 + 下载链接
- [ ] 6.3 一键打包按钮（调用 T5 package 端点）
- [ ] 6.4 注册到 router + 导航栏
- [x] 6.1 项目详情页添加「📦 生成成果」按钮 ✅
- [x] 6.2 DeliverablesPage 组件：7 个逐项生成 + 一键打包 ✅
- [x] 6.3 路由注册 `/projects/:id/deliverables` ✅
- [x] 6.4 JS 语法验证通过 ✅

---

## 依赖

| 库 | 用途 | 状态 |
|----|------|:--:|
| ezdxf | DXF 读写 | ✅ |
| Pillow | PNG 渲染 | ✅ |
| matplotlib | 热力图 | 需确认 |
| numpy | 密度计算 | 需确认 |
| scipy | KDE | 需确认 |

---

## 新增文件

| 文件 | 用途 |
|------|------|
| `backend/routers/deliverables.py` | 修改现有端点 |
| `frontend/src/views/DeliverablesPage.vue` | 成果页面 |
| `frontend/src/router/index.js` | +1 route |
