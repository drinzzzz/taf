# PFA 亚宠展系统 开发计划

> 最后更新: 2026-08-09

## Phase 0: 基础设施 — 版本控制与备份体系 ✅

- [x] 0.1 Git 提交未追踪文件
- [x] 0.2 创建 DB 备份脚本 scripts/backup_pfa.sh
- [x] 0.3 更新 .gitignore
- [x] 0.4 执行首次完整备份 + commit + push

## Phase 1: 两阶段 OCR 管线 ✅

- [x] 分条扫描 (8 strips/hall, Qwen VL) + 旋转预处理
- [x] 展商模糊匹配 (difflib ≥ 0.80) + raw_company_name 留存
- [x] 可续传 checkpoint 机制 (ocr_checkpoint.json)
- [x] 28/28 展厅完成, 1868 booths (91% 覆盖), 1113 匹配

## Phase 2: 数据质量清洗 ✅

- [x] 噪声标签/短名/展位号模式清除
- [x] 同展商同展厅去重 + 孤悬展商清理

## Phase 3: 前端功能增强 ✅

- [x] 版本统一 (pfa/index.html 为权威, pfa.html → 301)
- [x] 搜索与筛选 (展位号/展商名, 按展厅过滤)
- [x] 逛展计划管理 (要看列表/导出/清空)
- [x] TAF 主导航加 PFA 入口 (target=_blank)
- [x] 移动端响应式 (汉堡菜单 + 全宽面板)

## Phase 4: API 增强 ✅

- [x] GET /api/pfa/search (统一搜索: q/hall/category)
- [x] GET/POST/DELETE /api/pfa/plans (计划 CRUD)
- [x] GET /api/pfa/stats (统计面板: booths/matched/halls/categories)
- [x] GET /api/pfa/exhibitors/{id} (展商详情 + booths)
