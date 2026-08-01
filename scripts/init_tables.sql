-- 它界 TAF 数据库初始化
-- 运行: docker exec -i taf-postgis psql -U postgres -d taf < init.sql

BEGIN;

-- ============================================
-- 评估标准插件表
-- ============================================
CREATE TABLE IF NOT EXISTS standard_plugins (
    id UUID PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    release_date TIMESTAMP NOT NULL,
    config JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 项目主表
-- ============================================
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    product_line VARCHAR(10) NOT NULL,
    phase VARCHAR(10) NOT NULL,
    standard_id UUID REFERENCES standard_plugins(id),
    status VARCHAR(20) DEFAULT 'draft',
    client_name VARCHAR(100),
    client_company VARCHAR(100),
    location TEXT,
    config JSONB,
    custom_weights JSONB,
    metadata JSONB,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP,
    center GEOMETRY(POINT, 4326),
    boundary GEOMETRY(POLYGON, 4326)
);

CREATE INDEX IF NOT EXISTS idx_projects_code ON projects(code);
CREATE INDEX IF NOT EXISTS idx_projects_standard ON projects(standard_id);
CREATE INDEX IF NOT EXISTS idx_projects_center ON projects USING GIST(center);
CREATE INDEX IF NOT EXISTS idx_projects_deleted ON projects(deleted_at);

-- ============================================
-- 设施清单表
-- ============================================
CREATE TABLE IF NOT EXISTS facilities (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    standard_item_id VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    category VARCHAR(10) NOT NULL,
    status VARCHAR(20) DEFAULT 'draft',
    quantity INTEGER DEFAULT 1,
    position JSONB,
    spec JSONB,
    supplier VARCHAR(100),
    price NUMERIC(10,2),
    notes TEXT,
    custom_fields JSONB,
    installed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    location GEOMETRY(POINT, 4326)
);

CREATE INDEX IF NOT EXISTS idx_facilities_project ON facilities(project_id);
CREATE INDEX IF NOT EXISTS idx_facilities_status ON facilities(status);
CREATE INDEX IF NOT EXISTS idx_facilities_location ON facilities USING GIST(location);

-- ============================================
-- 空间实体表
-- ============================================
CREATE TABLE IF NOT EXISTS spaces (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    basemap_id UUID,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    geometry GEOMETRY(GEOMETRY, 4326),
    properties JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spaces_project ON spaces(project_id);
CREATE INDEX IF NOT EXISTS idx_spaces_geometry ON spaces USING GIST(geometry);

-- ============================================
-- 底图表
-- ============================================
CREATE TABLE IF NOT EXISTS basemaps (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    file_type VARCHAR(20) NOT NULL,
    file_url TEXT,
    width INTEGER,
    height INTEGER,
    transform JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE spaces ADD CONSTRAINT fk_spaces_basemap 
    FOREIGN KEY (basemap_id) REFERENCES basemaps(id) ON DELETE SET NULL;

COMMIT;

SELECT 'Tables created successfully' AS result;
