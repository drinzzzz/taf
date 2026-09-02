"""
它界 TAF — Pydantic 请求/响应模型
"""
from datetime import datetime
from typing import Optional, List, Dict, Any
from uuid import UUID
from pydantic import BaseModel, Field


# ── 标准插件 ──

class StandardPluginCreate(BaseModel):
    code: str = Field(..., max_length=50)
    name: str = Field(..., max_length=100)
    version: str = Field(..., max_length=20)
    status: str = "active"
    release_date: datetime
    config: Dict[str, Any]


class StandardPluginOut(BaseModel):
    id: UUID
    code: str
    name: str
    version: str
    status: str
    release_date: datetime
    config: Dict[str, Any]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class StandardPluginBrief(BaseModel):
    id: UUID
    code: str
    name: str
    version: str
    status: str

    model_config = {"from_attributes": True}


# ── 项目 ──

class ProjectCreate(BaseModel):
    name: str = Field(..., max_length=100)
    description: Optional[str] = None
    product_line: str = Field(..., max_length=10)
    phase: str = Field(..., max_length=10)
    standard_id: Optional[UUID] = None
    client_name: Optional[str] = None
    client_company: Optional[str] = None
    location: Optional[str] = None
    custom_weights: Optional[Dict[str, float]] = None


class ProjectUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    product_line: Optional[str] = None
    phase: Optional[str] = None
    status: Optional[str] = None
    client_name: Optional[str] = None
    client_company: Optional[str] = None
    location: Optional[str] = None
    custom_weights: Optional[Dict[str, float]] = None


class ProjectOut(BaseModel):
    id: UUID
    code: str
    name: str
    description: Optional[str]
    product_line: str
    phase: str
    standard_id: Optional[UUID]
    status: str
    client_name: Optional[str]
    client_company: Optional[str]
    location: Optional[str]
    custom_weights: Optional[Dict]
    created_at: datetime
    updated_at: datetime
    facility_count: Optional[int] = None
    score: Optional[float] = None
    level: Optional[str] = None

    model_config = {"from_attributes": True}


class ProjectListOut(BaseModel):
    items: List[ProjectOut]
    total: int
    page: int
    page_size: int


# ── 设施 ──

class FacilityCreate(BaseModel):
    standard_item_id: str = Field(..., max_length=50)
    name: str = Field(..., max_length=100)
    type: str = Field(..., max_length=20)  # prerequisite / credit
    category: str = Field(..., max_length=10)
    status: str = "draft"
    quantity: int = 1
    position: Optional[Dict] = None
    spec: Optional[Dict] = None
    supplier: Optional[str] = None
    price: Optional[float] = None
    notes: Optional[str] = None
    custom_fields: Optional[Dict] = None


class FacilityUpdate(BaseModel):
    name: Optional[str] = None
    status: Optional[str] = None
    quantity: Optional[int] = None
    position: Optional[Dict] = None
    spec: Optional[Dict] = None
    supplier: Optional[str] = None
    price: Optional[float] = None
    notes: Optional[str] = None
    custom_fields: Optional[Dict] = None


class FacilityOut(BaseModel):
    id: UUID
    project_id: UUID
    standard_item_id: str
    name: str
    type: str
    category: str
    status: str
    quantity: int
    position: Optional[Dict]
    spec: Optional[Dict]
    supplier: Optional[str]
    price: Optional[float]
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class FacilityBatchCreate(BaseModel):
    facilities: List[FacilityCreate]


# ── 布点实例 (一标准项多点位) ──

class PlacementIn(BaseModel):
    facility_id: Optional[UUID] = None   # 一般由 URL 提供
    position: Dict   # {x, y, lng, lat}
    seq: Optional[int] = None   # 缺省 = 自动取 max+1


class PlacementUpdate(BaseModel):
    position: Optional[Dict] = None
    seq: Optional[int] = None


class PlacementOut(BaseModel):
    id: UUID
    facility_id: UUID
    project_id: UUID
    seq: int
    position: Dict
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# ── 空间 ──

class SpaceCreate(BaseModel):
    name: str = Field(..., max_length=100)
    type: str = Field(..., max_length=20)
    basemap_id: Optional[UUID] = None
    geometry: Optional[Dict] = None  # GeoJSON
    properties: Optional[Dict] = None


class SpaceOut(BaseModel):
    id: UUID
    project_id: UUID
    name: str
    type: str
    properties: Optional[Dict]
    created_at: datetime

    model_config = {"from_attributes": True}


# ── 底图 ──

class BasemapOut(BaseModel):
    id: UUID
    project_id: UUID
    name: str
    file_type: str
    file_url: Optional[str]
    width: Optional[int]
    height: Optional[int]
    created_at: datetime

    model_config = {"from_attributes": True}


# ── 评估结果 ──

class CategoryScore(BaseModel):
    category_id: str
    category_name: str
    weight: float
    score: float
    max_score: float
    percentage: float
    items: List[Dict[str, Any]]


class EvaluationResult(BaseModel):
    project_id: UUID
    standard_code: str
    standard_name: str
    total_score: float
    max_total: int = 100
    level: str
    stars: int
    prerequisite_pass: bool
    prerequisite_total: int
    prerequisite_passed: int
    category_scores: List[CategoryScore]
    recommendations: List[str] = []


class ScoreHistory(BaseModel):
    id: UUID
    project_id: UUID
    standard_code: str
    total_score: float
    level: str
    stars: int
    evaluated_at: datetime


class StandardSwitchRequest(BaseModel):
    new_standard_code: str


class StandardImpactPreview(BaseModel):
    current_code: str
    new_code: str
    score_change: Optional[float]
    level_change: Optional[str]
    new_prerequisites: List[str]
    removed_items: List[str]


class AutoPlaceRequest(BaseModel):
    rules_override: Optional[Dict] = None


class AutoPlaceResult(BaseModel):
    generated_facilities: List[FacilityCreate]
    total: int
    warnings: List[str] = []
