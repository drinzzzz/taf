"""
TAF — 策划设计成果生成路由（模块化拆分）

Phase 1: BOQ + 优先级矩阵 + 交叉评估 + 方案书 + 打包器
Phase 2: 图纸引擎 + 叙事引擎 + 渲染管线
Phase 3: 版本管理 + ComfyUI 渲染对接

模块:
  helpers       — 共享辅助函数 (_get_project, _get_standard, _get_facilities, _get_all_standards)
  reports       — BOQ + 优先级矩阵 + 交叉评估
  proposal      — 方案书 + 成果打包器
  layout        — DXF 布点图
  visualization — 标注渲染图 + 热力图 + 叙事引擎 + AI 提示词
  versioning    — 版本管理 + ComfyUI 渲染对接
"""
from fastapi import APIRouter

from .reports import router as reports_router
from .proposal import router as proposal_router
from .layout import router as layout_router
from .visualization import router as visualization_router
from .versioning import router as versioning_router

# 聚合 router（子路由已自带 /api/projects 前缀，此处不加）
router = APIRouter()
router.include_router(reports_router)
router.include_router(proposal_router)
router.include_router(layout_router)
router.include_router(visualization_router)
router.include_router(versioning_router)
