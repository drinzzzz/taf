"""
它界 TAF — SQLAlchemy 数据库模型
"""
import uuid
from datetime import datetime
from sqlalchemy import (
    Column, String, Integer, Float, Text, Boolean, DateTime,
    ForeignKey, Index, JSON, Numeric, text
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import DeclarativeBase, relationship
from geoalchemy2 import Geometry


class Base(DeclarativeBase):
    pass


def gen_uuid():
    return uuid.uuid4()


class StandardPlugin(Base):
    """评估标准插件"""
    __tablename__ = "standard_plugins"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    code = Column(String(50), unique=True, nullable=False)
    name = Column(String(100), nullable=False)
    version = Column(String(20), nullable=False)
    status = Column(String(20), default="active")  # active / preview / archived
    release_date = Column(DateTime, nullable=False)
    config = Column(JSONB, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    projects = relationship("Project", back_populates="standard")


class Project(Base):
    """项目主表"""
    __tablename__ = "projects"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    code = Column(String(50), unique=True, nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    product_line = Column(String(10), nullable=False)  # HT/OS/AP/HO/RE/OF
    phase = Column(String(10), nullable=False)  # NC/EI/CO
    standard_id = Column(UUID(as_uuid=True), ForeignKey("standard_plugins.id"))
    status = Column(String(20), default="draft")  # draft/active/completed/archived
    client_name = Column(String(100))
    client_company = Column(String(100))
    location = Column(Text)
    config = Column(JSONB)
    custom_weights = Column(JSONB)
    metadata_ = Column("metadata", JSONB)
    created_by = Column(String(100))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    deleted_at = Column(DateTime)

    # PostGIS
    center = Column(Geometry("POINT", srid=4326))
    boundary = Column(Geometry("POLYGON", srid=4326))

    standard = relationship("StandardPlugin", back_populates="projects")
    facilities = relationship("Facility", back_populates="project", cascade="all, delete-orphan")
    spaces = relationship("Space", back_populates="project", cascade="all, delete-orphan")
    basemaps = relationship("Basemap", back_populates="project", cascade="all, delete-orphan")
    deliverables = relationship("Deliverable", back_populates="project", cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_projects_code", "code"),
        Index("idx_projects_standard", "standard_id"),
        Index("idx_projects_center", "center", postgresql_using="gist"),
        Index("idx_projects_deleted", "deleted_at"),
    )


class Facility(Base):
    """设施清单"""
    __tablename__ = "facilities"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    standard_item_id = Column(String(50), nullable=False)
    name = Column(String(100), nullable=False)
    type = Column(String(20), nullable=False)  # prerequisite / credit
    category = Column(String(10), nullable=False)  # P1-P6
    status = Column(String(20), default="draft")  # draft/selected/confirmed/installed
    quantity = Column(Integer, default=1)
    position = Column(JSONB)  # {x, y, basemap_id, lng, lat}
    spec = Column(JSONB)
    supplier = Column(String(100))
    price = Column(Numeric(10, 2))
    notes = Column(Text)
    custom_fields = Column(JSONB)
    installed_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # PostGIS
    location = Column(Geometry("POINT", srid=4326))

    project = relationship("Project", back_populates="facilities")

    __table_args__ = (
        Index("idx_facilities_project", "project_id"),
        Index("idx_facilities_status", "status"),
        Index("idx_facilities_location", "location", postgresql_using="gist"),
    )


class Space(Base):
    """空间实体"""
    __tablename__ = "spaces"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    basemap_id = Column(UUID(as_uuid=True), ForeignKey("basemaps.id"))
    name = Column(String(100), nullable=False)
    type = Column(String(20), nullable=False)  # building/channel/node/transition/facade/green
    geometry = Column(Geometry("GEOMETRY", srid=4326))
    properties = Column(JSONB)  # {width, length, area, material, shading, ...}
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    project = relationship("Project", back_populates="spaces")
    basemap = relationship("Basemap", back_populates="spaces")

    __table_args__ = (
        Index("idx_spaces_project", "project_id"),
        Index("idx_spaces_geometry", "geometry", postgresql_using="gist"),
    )


class Basemap(Base):
    """底图文件"""
    __tablename__ = "basemaps"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    file_type = Column(String(20), nullable=False)  # jpg/png/dxf/js3d
    file_url = Column(Text)  # COS URL or local path
    width = Column(Integer)
    height = Column(Integer)
    transform = Column(JSONB)  # {scale, offset_x, offset_y, rotation, srid}
    created_at = Column(DateTime, default=datetime.utcnow)

    project = relationship("Project", back_populates="basemaps")
    spaces = relationship("Space", back_populates="basemap")


class Deliverable(Base):
    """成果快照 — 版本管理"""
    __tablename__ = "deliverables"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    phase = Column(String(10), nullable=False)  # NC/EI/CO
    version = Column(Integer, nullable=False, default=1)
    files = Column(JSONB, nullable=False, default=list)  # [{name, format, size_bytes, nutstore_path}]
    config_snapshot = Column(JSONB, nullable=True)  # 生成时的标准配置快照
    generated_at = Column(DateTime, default=datetime.utcnow)

    project = relationship("Project", back_populates="deliverables")


class ScoreHistory(Base):
    """评分历史"""
    __tablename__ = "score_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    standard_code = Column(String(50), nullable=False)
    total_score = Column(Float, nullable=False)
    level = Column(String(50))
    stars = Column(Integer)
    evaluated_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        Index("idx_score_history_project", "project_id"),
        Index("idx_score_history_evaluated", "evaluated_at"),
    )


class StandardChangeLog(Base):
    """标准切换日志"""
    __tablename__ = "standard_change_log"

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    from_standard_code = Column(String(50))
    to_standard_code = Column(String(50), nullable=False)
    impact_summary = Column(JSONB)
    applied_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        Index("idx_change_log_project", "project_id"),
    )
