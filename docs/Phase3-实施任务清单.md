# Phase 3 实施任务清单

> 创建时间: 2026-08-02
> 当前状态: ✅ 已完成

---

| # | 模块 | 端点 | 状态 |
|---|------|------|:--:|
| T1 | 版本管理 | `GET .../history` `POST .../diff` | ✅ |
| T2 | ComfyUI 对接 | `POST .../render` | ✅ |

---

## T1: 版本管理

- [x] `Deliverable` 模型（project_id/phase/version/files/config_snapshot/generated_at）
- [x] 包端点自动保存快照（version 自增）
- [x] `GET .../history` — 版本列表
- [x] `POST .../diff?v1=1&v2=2` — 文件级对比（added/modified/removed）
- [x] 验证：v1/v2 差异检测 ✅

## T2: ComfyUI 渲染对接

- [x] `POST .../render` 端点
- [x] dry-run 模式：输出 21 个 prompt 就绪
- [x] 实时模式：检测 ComfyUI 运行 → 自动提交 SDXL 工作流
- [x] `?space_index=N` 参数支持单空间渲染
