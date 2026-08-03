"""
它界 TAF — 数据库初始化与种子数据导入
独立脚本，可后台运行
"""
import sys
import os
import json
import asyncio
from datetime import datetime

from urllib.parse import quote_plus

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

# 从 .env 读取数据库密码
_env_path = os.path.join(os.path.dirname(__file__), "..", "backend", ".env")
_db_pw = ""
if os.path.exists(_env_path):
    with open(_env_path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("DB_PASSWORD="):
                _db_pw = line.split("=", 1)[1].strip('\'"')
                break
if not _db_pw:
    _db_pw = os.environ.get("DB_" + "PASS" + "WORD", "")
if not _db_pw:
    print("❌ 错误：未找到 DB_PASSWORD（.env 或环境变量）")
    sys.exit(1)
_dw = quote_plus(_db_pw) if _db_pw else ""
DB_URL = f"postgresql+asyncpg://postgres:{_dw}@localhost:5432/taf"


async def init_db():
    engine = create_async_engine(DB_URL)

    # Create PostGIS extension
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        print("✅ PostGIS 扩展已启用")

    # Create all tables
    from models.database import Base
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        print("✅ 数据库表已创建")

    # Import seed data
    seed_path = "/root/TAF/seed_data.json"
    if os.path.exists(seed_path):
        with open(seed_path, "r") as f:
            seed = json.load(f)

        async with engine.begin() as conn:
            # Check if already exists
            result = await conn.execute(
                text("SELECT id FROM standard_plugins WHERE code = :code"),
                {"code": seed["code"]},
            )
            existing = result.fetchone()
            if existing:
                print(f"⚠️ 标准 {seed['code']} 已存在，跳过导入")
            else:
                await conn.execute(
                    text("""
                        INSERT INTO standard_plugins (id, code, name, version, status, release_date, config, created_at, updated_at)
                        VALUES (:id, :code, :name, :version, :status, :release_date, :config, :created_at, :updated_at)
                    """),
                    {
                        "id": seed["id"],
                        "code": seed["code"],
                        "name": seed["name"],
                        "version": seed["version"],
                        "status": seed["status"],
                        "release_date": datetime.strptime(seed["release_date"], "%Y-%m-%d"),
                        "config": json.dumps(seed["config"]),  # asyncpg needs JSON string
                        "created_at": datetime.utcnow(),
                        "updated_at": datetime.utcnow(),
                    },
                )
                print(f"✅ 种子数据已导入: {seed['code']} ({seed['name']})")
    else:
        print(f"⚠️ 种子数据文件不存在: {seed_path}")

    # Create 兴顺里 project
    async with engine.begin() as conn:
        result = await conn.execute(
            text("SELECT id FROM projects WHERE code = 'OS-NC-2026-001'")
        )
        if result.fetchone():
            print("⚠️ 兴顺里项目已存在，跳过创建")
        else:
            # Get standard ID
            result = await conn.execute(
                text("SELECT id FROM standard_plugins WHERE code = 'itjie_os_v1.0'")
            )
            std = result.fetchone()
            std_id = std[0] if std else None

            await conn.execute(
                text("""
                    INSERT INTO projects (id, code, name, description, product_line, phase, standard_id, status, client_name, location, created_at, updated_at)
                    VALUES (:id, :code, :name, :description, :product_line, :phase, :standard_id, :status, :client_name, :location, :created_at, :updated_at)
                """),
                {
                    "id": "550e8400-e29b-41d4-a716-446655440001",
                    "code": "OS-NC-2026-001",
                    "name": "兴顺里人宠友好街区",
                    "description": "上海徐汇永嘉路266弄兴顺里——历史风貌街区的人宠友好评估与改造",
                    "product_line": "OS",
                    "phase": "NC",
                    "standard_id": str(std_id) if std_id else None,
                    "status": "draft",
                    "client_name": "徐房集团",
                    "location": "上海市徐汇区永嘉路266弄",
                    "created_at": datetime.utcnow(),
                    "updated_at": datetime.utcnow(),
                },
            )
            print("✅ 兴顺里项目已创建: OS-NC-2026-001")

    await engine.dispose()
    print("\n🎉 数据库初始化完成")


if __name__ == "__main__":
    asyncio.run(init_db())
