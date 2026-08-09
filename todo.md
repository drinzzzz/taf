# PFA 亚宠展系统 开发计划

> 最后更新: 2026-08-09

## Phase 0: 基础设施 — 版本控制与备份体系

- [x] 0.1 Git 提交未追踪文件 (pfa_api.py, frontend/pfa*, docs/, scripts/)
- [x] 0.2 创建 DB 备份脚本 scripts/backup_pfa.sh
- [x] 0.3 更新 .gitignore (确认 seed*.sql 已解除排除)
- [x] 0.4 执行首次完整备份 + commit + push

## Phase 1: 两阶段 OCR 管线

### Stage A: 粗筛 — 全图 OCR + Qwen VL 结构识别
- [ ] 1.A1 旋转预处理验证 (cv2 rotate 逆时针90°)
- [ ] 1.A2 全图 OCR 文字提取 (PaddleOCR/EasyOCR)
- [ ] 1.A3 Qwen VL 展厅结构识别 (网格行列数、有效区域 bbox)

### Stage B: 精确 — 网格切分 + 逐格 Qwen VL 识别
- [ ] 1.B1 网格线检测 (W1 最小展厅先验证参数)
- [ ] 1.B2 逐格切分 + 空cell预过滤
- [ ] 1.B3 逐格 Qwen VL OCR (批量并发 5-10格)
- [ ] 1.B4 展位↔展商 模糊匹配关联
- [ ] 1.B5 全量验证 (booths 数 vs halls.booth_count)

## Phase 2: 数据质量清洗

- [ ] 2.1 污染数据清除 (E8D28 E8D29 等展位号混入展商名)
- [ ] 2.2 展商分类 (2023条, Qwen 批量, 50条/批)
- [ ] 2.3 展商去重合并 (编辑距离检测)

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
