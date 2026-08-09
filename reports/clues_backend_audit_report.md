# CLUES 后端代码审计报告

**审计日期**: 2026-06-07  
**项目路径**: `/www/wwwroot/clues/clues_website/backend/`  
**审计范围**: 22 个 Python 文件  
**技术栈**: FastAPI + SQLAlchemy 2.0 + Pydantic v2 + MySQL

---

## 执行摘要

| 严重等级 | 问题数量 |
|---------|---------|
| 🔴 高 (High) | 6 |
| 🟡 中 (Medium) | 12 |
| 🟢 低 (Low) | 8 |
| **总计** | **26** |

---

## 🔴 高严重性问题 (High Severity)

### H1. 敏感信息硬编码 - 数据库密码和 JWT 密钥
- **文件**: `config.py` (第 17, 25 行)
- **问题描述**: 
  - `DB_PASSWORD` 默认值为 `'RaDe4321'`
  - `SECRET_KEY` 默认值为 `'darrin-wong-20260501-v2'`
  - 如果环境变量未设置，将使用这些弱默认值
- **风险**: 攻击者可通过默认凭证访问数据库或伪造 JWT token
- **修复建议**:
  ```python
  # 强制要求环境变量存在，否则抛出异常
  DB_PASSWORD: str = os.environ['DB_PASSWORD']  # 移除默认值
  SECRET_KEY: str = os.environ['SECRET_KEY']    # 移除默认值
  
  # 或在应用启动时检查
  if not os.environ.get('SECRET_KEY'):
      raise RuntimeError("SECRET_KEY environment variable is required")
  ```

### H2. CORS 配置过于宽松
- **文件**: `main.py` (第 32-38 行)
- **问题描述**: 
  ```python
  allow_origins=['*'],
  allow_credentials=True,  # 与通配符 origins 一起使用不安全
  ```
- **风险**: 允许任何网站通过凭证访问 API，可能导致 CSRF 攻击
- **修复建议**:
  ```python
  # 明确指定允许的来源
  app.add_middleware(
      CORSMiddleware,
      allow_origins=settings.ALLOWED_ORIGINS.split(','),  # 从环境变量读取
      allow_credentials=True,
      allow_methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
      allow_headers=['Authorization', 'Content-Type'],
  )
  ```

### H3. 评估计算逻辑未使用 - 占位实现
- **文件**: `routers/assessments.py` (第 17-32 行)
- **问题描述**: `calculate_personality()` 函数是占位实现，返回硬编码结果，未调用 `services/personality.py` 中的实际算法
- **风险**: 所有评估都返回相同的性格类型，系统功能失效
- **修复建议**:
  ```python
  from services.personality import calculate_clue_code, get_personality_info, load_description
  
  def calculate_personality(scores: list, species: str) -> dict:
      clue_code, dimensions = calculate_clue_code(scores)
      personality_info = get_personality_info(species, clue_code)
      description = load_description(species, clue_code)
      
      return {
          "clue_code": clue_code,
          "clue_role": personality_info['nickname'] if personality_info else "未知",
          "clue_slogan": personality_info['slogan'] if personality_info else "",
          "pathway_name": personality_info['pathway_name'] if personality_info else None,
          "pathway_emoji": personality_info['pathway_emoji'] if personality_info else None,
          "pathway_color": personality_info['pathway_color'] if personality_info else None,
          "sequence": personality_info['sequence'] if personality_info else None,
          "dimensions": dimensions,
          "full_description": description,
      }
  ```

### H4. 分数输入验证不完整
- **文件**: `schemas/__init__.py` (第 17 行)
- **问题描述**: `scores` 字段只验证长度为 25，未验证每个分数是否在 1-5 范围内
- **风险**: 可能存入无效分数数据，影响评估结果准确性
- **修复建议**:
  ```python
  from pydantic import Field, field_validator
  
  class AssessmentCreate(BaseModel):
      scores: List[int] = Field(..., min_length=25, max_length=25)
      
      @field_validator('scores', mode='before')
      @classmethod
      def validate_scores(cls, v):
          if not all(1 <= s <= 5 for s in v):
              raise ValueError('每个分数必须在 1-5 范围内')
          return v
  ```

### H5. 文件路径遍历风险
- **文件**: `routers/personality.py` (第 57 行), `services/personality.py` (第 211 行)
- **问题描述**: 用户提供的 `code` 参数直接用于构建文件路径，未进行充分验证
- **风险**: 攻击者可能通过 `../` 读取敏感文件
- **修复建议**:
  ```python
  # 验证 code 格式
  import re
  if not re.match(r'^[A-Z]{5}$', code):
      raise HTTPException(status_code=400, detail="无效的性格代码格式")
  
  # 使用 Path.resolve() 确保路径在预期目录内
  md_file_path = (Path(settings.DATA_DIR) / species / f"{code}.md").resolve()
  if not str(md_file_path).startswith(str(Path(settings.DATA_DIR).resolve())):
      raise HTTPException(status_code=400, detail="无效的文件路径")
  ```

### H6. 登录接口缺少速率限制
- **文件**: `routers/auth.py` (第 58-82 行)
- **问题描述**: `/api/auth/login` 接口没有速率限制，容易受到暴力破解攻击
- **风险**: 攻击者可尝试大量密码组合
- **修复建议**:
  ```python
  from slowapi import SlowAPILimiter, _rate_limit_exceeded_handler
  from slowapi.errors import RateLimitExceeded
  from slowapi.util import get_remote_address
  
  # 在 main.py 中配置
  limiter = SlowAPILimiter()
  app.state.limiter = limiter
  
  # 在登录接口添加限制
  @router.post('/login')
  @limiter.limit("5/minute")  # 每分钟最多 5 次登录尝试
  def login(...):
      ...
  ```

---

## 🟡 中严重性问题 (Medium Severity)

### M1. 日期解析缺少异常处理
- **文件**: `routers/admin/activities.py` (第 78-80, 125-132 行), `routers/admin/records.py` (第 55-58 行), `routers/admin/export.py` (第 48-50 行), `routers/admin/daily_report.py` (第 69-74, 88-94 行)
- **问题描述**: `datetime.fromisoformat()` 和 `datetime.strptime()` 在格式错误时抛出异常，部分有处理但不一致
- **修复建议**: 统一使用 try-except 包装所有日期解析逻辑，返回友好的错误信息

### M2. CSV 导出存在公式注入风险
- **文件**: `routers/admin/export.py` (第 60-97 行)
- **问题描述**: 用户输入的数据（如 pet_name, channel）直接写入 CSV，可能包含 `=CMD()` 等公式
- **风险**: 打开 CSV 时可能执行恶意命令
- **修复建议**:
  ```python
  def sanitize_csv_field(value: str) -> str:
      if value and str(value)[0] in ['=', '+', '-', '@', '\t', '\r']:
          return f"'{value}"  # 添加前缀单引号
      return str(value)
  ```

### M3. 密码强度要求过低
- **文件**: `schemas/__init__.py` (第 88 行), `routers/admin/admins.py` (第 40-79 行)
- **问题描述**: 管理员密码最小长度仅为 4 字符，无复杂度要求
- **修复建议**:
  ```python
  class AdminCreate(BaseModel):
      password: str = Field(..., min_length=8, max_length=128)
      
      @field_validator('password')
      @classmethod
      def validate_password(cls, v):
          if not re.search(r'[A-Z]', v) or not re.search(r'[a-z]', v) or not re.search(r'\d', v):
              raise ValueError('密码必须包含大小写字母和数字')
          return v
  ```

### M4. 数据库连接字符串暴露风险
- **文件**: `config.py` (第 20-22 行)
- **问题描述**: `DATABASE_URL` 属性用 `***` 隐藏密码，但实际 `database.py` 使用的是完整连接字符串
- **修复建议**: 移除 `DATABASE_URL` 属性，直接在 `database.py` 中构建连接字符串，确保日志中不暴露密码

### M5. 健康检查暴露版本信息
- **文件**: `routers/health.py` (第 30 行)
- **问题描述**: 返回具体版本号 `"version": "2.0.0"`
- **风险**: 帮助攻击者识别已知漏洞
- **修复建议**: 移除版本号或仅返回 `"ok"` 状态

### M6. 维护模式中间件异常处理过宽
- **文件**: `main.py` (第 90 行)
- **问题描述**: `except:` 捕获所有异常，包括 `KeyboardInterrupt` 等
- **修复建议**:
  ```python
  except (json.JSONDecodeError, OSError) as e:
      logger.warning(f"维护模式文件读取失败：{e}")
      pass
  ```

### M7. 年龄转换精度损失
- **文件**: `routers/assessments.py` (第 60 行)
- **问题描述**: `int(assessment_data.pet_age * 12)` 会丢失小数部分
- **修复建议**: 使用 `round()` 或直接在 schema 中接收月龄

### M8. 活动状态更新缺少权限检查
- **文件**: `routers/admin/activities.py` (第 143-171 行)
- **问题描述**: `PATCH /{activity_id}/status` 只检查 admin 角色，未验证是否为活动创建者
- **修复建议**: 添加创建者检查或使用更细粒度的权限控制

### M9. Markdown 渲染允许过多标签
- **文件**: `services/personality.py` (第 219-230 行)
- **问题描述**: bleach 允许的标签列表包含 `script` 可能的载体标签如 `img`, `a`
- **修复建议**: 进一步限制允许的属性和协议
  ```python
  allowed_attrs = {
      'a': ['href', 'title'],
      'img': ['src', 'alt', 'title'],  # 移除 width, height
      # 移除 span, div 的 class 属性或限制为白名单
  }
  # 限制 href 协议
  bleach.clean(html, tags=allowed_tags, attributes=allowed_attrs, 
               protocols={'href': ['http', 'https', 'mailto']})
  ```

### M10. 缺少请求体大小限制
- **文件**: `main.py`
- **问题描述**: 未配置 FastAPI 的请求体大小限制
- **风险**: 可能导致 DoS 攻击
- **修复建议**:
  ```python
  app = FastAPI(...)
  app.config.max_body_size = 10 * 1024 * 1024  # 10MB
  ```

### M11. 数据库会话未使用异步
- **文件**: `database.py`, 所有路由文件
- **问题描述**: 使用同步 SQLAlchemy 会话，在 FastAPI 异步环境中可能阻塞
- **修复建议**: 考虑迁移到 `asyncpg` + `SQLAlchemy 2.0 async`

### M12. 日志可能泄露敏感信息
- **文件**: `main.py` (第 45-52 行)
- **问题描述**: 请求日志中间件记录所有请求路径，可能包含敏感参数
- **修复建议**: 脱敏敏感路径或使用结构化日志

---

## 🟢 低严重性问题 (Low Severity)

### L1. 重复导入
- **文件**: `routers/admin/records.py` (第 5, 54-57 行)
- **问题描述**: `datetime` 在文件顶部和函数内部重复导入
- **修复建议**: 移除函数内部的导入

### L2. 空 __init__.py 文件
- **文件**: `routers/__init__.py`, `routers/admin/__init__.py`, `models/__init__.py`, `services/__init__.py`
- **问题描述**: 空文件，可以移除或添加模块导出
- **修复建议**: 添加 `__all__` 导出或移除（Python 3.3+ 不需要）

### L3. 数据库连接池配置
- **文件**: `database.py` (第 10-16 行)
- **问题描述**: `pool_size=10` 在高并发下可能不足
- **修复建议**: 根据预期负载调整，或添加 `max_overflow`

### L4. 缺少 API 版本管理
- **文件**: `main.py`
- **问题描述**: API 路径无版本前缀
- **修复建议**: 使用 `/api/v1/...` 前缀便于未来升级

### L5. 评估记录缺少唯一性约束
- **文件**: `models/models.py`
- **问题描述**: `PetAssessment` 表无业务唯一性约束
- **修复建议**: 考虑添加 `(pet_name, pet_species, created_at)` 联合索引

### L6. 错误响应格式不统一
- **文件**: 多个路由文件
- **问题描述**: 部分使用 `HTTPException`，部分直接返回 dict
- **修复建议**: 统一使用异常处理器格式化错误响应

### L7. 缺少 OpenAPI 文档定制
- **文件**: `main.py`
- **问题描述**: 使用默认 Swagger UI，未定制安全方案
- **修复建议**: 添加 `security_schemes` 配置

### L8. create_tables.py 功能不完整
- **文件**: `create_tables.py`
- **问题描述**: 只创建 `PersonalityType` 表，其他表未处理
- **修复建议**: 完善为完整的数据库初始化脚本

---

## 代码质量观察

### ✅ 优点
1. **SQLAlchemy 2.0 风格**: 使用现代声明式语法
2. **依赖注入**: 正确使用 FastAPI 的 Depends 机制
3. **角色权限**: 实现了基于角色的访问控制 (RBAC)
4. **Pydantic v2**: 使用最新版本的 Pydantic 进行数据验证
5. **密码哈希**: 使用 bcrypt 加密存储密码
6. **时区处理**: 使用 pytz 处理时区

### ⚠️ 改进建议
1. **类型注解**: 部分函数缺少返回类型注解
2. **文档字符串**: 部分函数缺少 docstring
3. **单元测试**: 未见测试文件，建议添加 pytest 测试
4. **日志配置**: 使用 `print()` 而非 `logging` 模块
5. **环境变量验证**: 启动时应验证必需的环境变量

---

## 修复优先级建议

| 优先级 | 问题编号 | 预计工作量 |
|-------|---------|-----------|
| P0 (立即) | H1, H2, H3, H6 | 4-8 小时 |
| P1 (本周) | H4, H5, M1, M3, M6 | 4-6 小时 |
| P2 (本月) | M2, M4, M5, M8, M9 | 6-10 小时 |
| P3 (后续) | L1-L8, M7, M10-M12 | 8-16 小时 |

---

## 总结

CLUES 后端代码整体结构清晰，使用了现代化的技术栈。但存在若干**严重的安全问题**需要立即修复，特别是：

1. **硬编码的敏感信息**（数据库密码、JWT 密钥）
2. **CORS 配置不当**
3. **核心评估逻辑未启用**
4. **输入验证不完整**
5. **缺少速率限制**

建议优先修复高严重性问题，然后逐步改进中低严重性问题。同时建议建立代码审查流程和安全测试机制。
