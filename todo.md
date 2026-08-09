# PFA 亚宠展系统 开发计划

> 最后更新: 2026-08-09

## Phase 0: 基础设施 — 版本控制与备份体系

- [x] 0.1 Git 提交未追踪文件 (pfa_api.py, frontend/pfa*, docs/, scripts/)
- [x] 0.2 创建 DB 备份脚本 scripts/backup_pfa.sh
- [x] 0.3 更新 .gitignore (确认 seed*.sql 已解除排除)
- [x] 0.4 执行首次完整备份 + commit + push

## Phase 1: 两阶段 OCR 管线 ✅ DONE

- [x] 1.A1 旋转预处理 (逐格 CCW 90°)
- [x] 1.A2 分条 OCR (8 strips/hall, Qwen VL)
- [x] 1.A3 展商模糊匹配 (difflib ratio ≥ 0.80)
- [x] 1.B1 数据入库 (28 展厅, 1868 booths, 1113 matched)
- [x] 1.B2 可续传 checkpoint 机制 (ocr_checkpoint.json)
- [x] 1.B3 原始输出留存 (raw_company_name 列)

### OCR 结果
- 28/28 展厅完成
- 1868 booths (预期 2061, 覆盖率 91%)
- 1113 匹配展商 (匹配率 60%)
- 备份: backups/pfa_phase1_ocr_done_20260809_151551.sql (494K)

## Phase 2: 数据质量清洗 ✅ DONE

- [x] 2.1 噪声标签清除 (功能区/优家/优宠/优尚 等 143 条)
- [x] 2.2 短名/展位号模式清除 (265 条)
- [x] 2.3 同展商同展厅去重 (114 条 → 每厅每展商仅 1 booth)
- [x] 2.4 孤悬展商清理 (66 条)

## Phase 3: 前端功能增强

- [ ] 3.1 版本统一 (pfa/index.html 为权威, pfa.html → 301)
- [ ] 3.2 搜索与筛选 (展位号/展商名/分类/状态)
- [ ] 3.3 逛展计划管理 (列表/拖拽排序/导出)
- [ ] 3.4 TAF 主导航加 PFA 入口
- [ ] 3.5 移动端响应式适配

## Phase 4: API 增强

- [ ] 4.1 GET /api/pfa/search (统一搜索)
- [ ] 4.2 GET/PUT /api/pfa/plans (计划管理)
- [ ] 4.3 GET /api/pfa/stats (统计面板)
- [ ] 4.4 GET /api/pfa/exhibitors/{id} (展商详情)
