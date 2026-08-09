# CLUES 宠物性格测试系统 - 安全与代码质量审计报告

**审计对象**: CLUES 宠物性格测试系统 (Flask 单体应用)  
**部署环境**: ENTH 生产机 43.154.76.118  
**审计日期**: 2026 年 6 月 9 日  
**审计范围**: 后端代码 (app.py, models.py, forms.py 等) + 前端模板 (8 个 HTML + 1 个 JS)

---

## 一、综合评分

| 维度 | 权重 | 得分 | 加权得分 |
|------|------|------|----------|
| 安全性 | 25% | 3.5/10 | 0.88 |
| 代码质量 | 20% | 5.5/10 | 1.10 |
| 架构设计 | 20% | 4.0/10 | 0.80 |
| 数据库设计 | 15% | 5.0/10 | 0.75 |
| 业务逻辑 | 10% | 7.0/10 | 0.70 |
| 前端质量 | 10% | 6.0/10 | 0.60 |
| **综合评分** | **100%** | - | **4.83/10** |

**评级**: ⚠️ **高风险** - 存在多个 P0/P1 级别安全漏洞，需立即修复

---

## 二、问题发现清单 (按优先级分级)

### 🔴 P0 - 紧急 (需 24 小时内修复)

#### P0-01: 管理员密码硬编码
- **文件**: `app.py` 第 21 行
- **问题**: `ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'RaDe4321')` - 默认密码硬编码在源码中
- **风险**: 任何查看源码的人都能获得管理员权限，可访问所有用户数据、开启/关闭维护模式
- **修复建议**: 
  ```python
  # 必须设置环境变量，不提供默认值
  ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD')
  if not ADMIN_PASSWORD:
      raise RuntimeError("ADMIN_PASSWORD environment variable must be set")
  ```
  并使用 bcrypt/argon2 进行密码哈希存储验证

#### P0-02: Flask SECRET_KEY 硬编码
- **文件**: `app.py` 第 34 行
- **问题**: `app.config['SECRET_KEY'] = 'darrin-wong-20260501'` - 密钥硬编码
- **风险**: 攻击者可伪造会话 cookie、CSRF token，劫持管理员会话
- **修复建议**:
  ```python
  app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY')
  if not app.config['SECRET_KEY']:
      app.config['SECRET_KEY'] = secrets.token_hex(32)
  ```

#### P0-03: 数据库凭证明文存储
- **文件**: `app.py` 第 35 行
- **问题**: `mysql+pymysql://clues_user:***@127.0.0.1/clues_db` - 虽然密码被脱敏 (***)，但连接字符串模式表明凭证明文存储在代码中
- **风险**: 数据库凭证泄露可导致数据泄露、篡改
- **修复建议**: 使用环境变量或配置文件 (不在版本控制中)
  ```python
  app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL')
  ```

#### P0-04: 无 CSRF 保护
- **文件**: `app.py` 多处表单路由
- **问题**: 虽然使用了 `form.hidden_tag()` (第 12 行 index.html)，但 `/feedback` API 端点 (第 403-423 行) 无 CSRF 验证
- **风险**: 攻击者可伪造请求进行点赞/质疑操作，或构造恶意表单提交
- **修复建议**:
  ```python
  from flask_wtf.csrf import CSRFProtect
  csrf = CSRFProtect(app)
  
  # 对 API 端点使用 @csrf.exempt 仅当必要时，或添加 CSRF token 验证
  ```

#### P0-05: 文件上传无类型验证绕过风险
- **文件**: `app.py` 第 116-117 行，`forms.py` 第 548 行
- **问题**: `allowed_file()` 仅检查扩展名，未验证 MIME 类型或文件头
- **风险**: 攻击者可上传 `.php` 或可执行脚本 (虽然限制了扩展名，但可通过双重扩展名绕过)
- **修复建议**:
  ```python
  import magic  # python-magic
  def allowed_file(filename, file_stream):
      # 检查扩展名
      if '.' not in filename: return False
      ext = filename.rsplit('.', 1)[1].lower()
      if ext not in ALLOWED_EXTENSIONS: return False
      # 检查 MIME 类型
      mime = magic.from_buffer(file_stream.read(1024), mime=True)
      return mime in ['image/png', 'image/jpeg', 'image/gif']
  ```

---

### 🟠 P1 - 高优先级 (需 1 周内修复)

#### P1-01: 会话固定攻击风险
- **文件**: `app.py` 第 436-443 行 (admin_login)
- **问题**: 登录成功后未重新生成会话 ID
- **风险**: 攻击者可预先设置会话 ID，诱导管理员登录后劫持会话
- **修复建议**:
  ```python
  from flask import session
  @app.route('/admin/login', methods=['POST'])
  def admin_login():
      # ... 验证密码 ...
      session.clear()  # 清除旧会话
      session.regenerate = True  # 或使用 flask-session 扩展
      session['admin_logged_in'] = True
  ```

#### P1-02: XSS 风险 - 结果页直接渲染 Markdown
- **文件**: `app.py` 第 147 行，`result.html` 第 616 行
- **问题**: `markdown.markdown(md_content, extensions=['extra'])` 未过滤 HTML，且模板使用 `|safe` 直接渲染
- **风险**: 若描述文件被篡改，可注入恶意脚本
- **修复建议**:
  ```python
  import bleach
  html = markdown.markdown(md_content, extensions=['extra'])
  clean_html = bleach.clean(html, tags=['p','br','strong','em','ul','ol','li','h1','h2','h3'], attributes={}, strip=True)
  ```

#### P1-03: SQL 注入风险 (低但存在)
- **文件**: `models.py` 第 503-504 行
- **问题**: 索引定义安全，但 `channel` 字段用于筛选时 (第 456-457 行) 使用 `filter_by` 是安全的，需确认无原始 SQL
- **风险**: 当前使用 SQLAlchemy ORM，风险较低，但需审计所有查询
- **修复建议**: 确保永不使用 `db.session.execute()` 执行拼接的 SQL 字符串

#### P1-04: 调试模式在生产环境
- **文件**: `app.py` 第 490 行
- **问题**: `app.run(debug=True)` - 虽然这是 `__main__` 块，但需确认生产环境不使用此入口
- **风险**: 调试模式开启会导致详细错误信息泄露、允许代码执行
- **修复建议**: 移除或添加环境检查
  ```python
  if __name__ == '__main__':
      if os.environ.get('FLASK_ENV') == 'production':
          raise RuntimeError("Cannot run in debug mode in production")
      app.run(debug=True)
  ```

#### P1-05: 无速率限制
- **文件**: 全局
- **问题**: 所有端点无请求频率限制
- **风险**: 暴力破解管理员密码、刷赞/刷质疑、DoS
- **修复建议**: 使用 `flask-limiter`
  ```python
  from flask_limiter import Limiter
  limiter = Limiter(app, key_func=lambda: request.remote_addr)
  
  @app.route('/admin/login', methods=['POST'])
  @limiter.limit("5 per minute")
  def admin_login():
      # ...
  ```

#### P1-06: 日志敏感信息泄露
- **文件**: `app.py` 第 30 行，`gunicorn_conf.py` 第 773-774 行
- **问题**: 日志级别为 INFO，可能记录请求参数 (含密码)
- **风险**: 密码、会话 ID 等敏感信息可能被记录到日志文件
- **修复建议**: 配置日志过滤器脱敏敏感字段

#### P1-07: 密码复杂度无要求
- **文件**: `admin_login.html` 第 856 行
- **问题**: 密码输入无最小长度、复杂度要求
- **风险**: 管理员可能设置弱密码
- **修复建议**: 前端 + 后端双重验证密码强度

---

### 🟡 P2 - 中优先级 (需 1 月内修复)

#### P2-01: 数据库字段重复定义
- **文件**: `models.py` 第 528 行和第 534 行
- **问题**: `created_at` 字段定义了两次
- **风险**: 可能导致不可预测的行为
- **修复建议**: 删除第 528 行，保留第 534 行 (带时区的版本)

#### P2-02: 分数存储为字符串
- **文件**: `models.py` 第 515-520 行
- **问题**: `scores_social` 等字段使用 `String(20)` 存储逗号分隔的数字
- **风险**: 无法进行数值查询、聚合，浪费存储空间
- **修复建议**: 使用 `JSON` 类型 (MySQL 5.7 支持) 或单独的关联表

#### P2-03: 无数据库备份策略
- **文件**: 全局
- **问题**: 代码中无备份机制
- **风险**: 数据丢失风险
- **修复建议**: 添加定时备份脚本

#### P2-04: 上传文件命名可预测
- **文件**: `app.py` 第 290 行
- **问题**: 使用 `uuid.uuid4()` 生成文件名是好的，但未对文件名进行哈希
- **风险**: 理论上 UUID 足够随机，但建议额外添加哈希
- **修复建议**: 当前实现可接受，但可增强为 `hashlib.sha256(uuid + timestamp).hexdigest()`

#### P2-05: 时区处理不一致
- **文件**: `app.py` 第 24-28 行，`models.py` 第 496 行
- **问题**: 同时使用 `time.tzset()` 和 `pytz`，`datetime.utcnow()` 和 `datetime.now(CHINA_TZ)` 混用
- **风险**: 时间戳可能不一致
- **修复建议**: 统一使用 UTC 存储，显示时转换

#### P2-06: 维护模式文件竞争条件
- **文件**: `app.py` 第 54-72 行
- **问题**: `maintenance.json` 读写无文件锁
- **风险**: 并发请求可能导致数据损坏
- **修复建议**: 使用 `fcntl` 文件锁或改用 Redis

#### P2-07: 错误处理不完善
- **文件**: `app.py` 第 143-151 行
- **问题**: `load_description()` 捕获所有异常但仅记录日志，返回 None
- **风险**: 用户看到不完整信息
- **修复建议**: 添加友好的错误提示

---

### ⚪ P3 - 低优先级 (建议优化)

#### P3-01: 代码重复
- **文件**: `app.py` 第 107-108 行，`generate_descriptions.py` 第 650-719 行
- **问题**: DOG_MAP 和 CAT_MAP 在两个文件中重复定义
- **修复建议**: 统一从 `dog_personality.py` 和 `cat_personality.py` 导入

#### P3-02: 魔法数字
- **文件**: `app.py` 第 134 行，第 180-184 行
- **问题**: `15` (总分阈值)、`25` (题目数) 等硬编码
- **修复建议**: 定义为常量

#### P3-03: 注释为中文
- **文件**: 全局
- **问题**: 注释均为中文，不利于国际化协作
- **修复建议**: 保持中文 (对国内团队可接受)，但关键 API 添加英文注释

#### P3-04: 无 API 版本控制
- **文件**: 全局
- **问题**: `/feedback` 等 API 无版本号
- **修复建议**: 添加 `/api/v1/feedback` 前缀

#### P3-05: 前端 JS 未压缩
- **文件**: `main.js`
- **问题**: 开发版 JS 直接用于生产
- **修复建议**: 使用构建工具压缩

#### P3-06: CDN 依赖无完整性校验
- **文件**: `result.html` 第 662-664 行
- **问题**: 引用外部 CDN 资源无 SRI (Subresource Integrity)
- **风险**: CDN 被篡改可注入恶意代码
- **修复建议**: 添加 `integrity` 和 `crossorigin` 属性
  ```html
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js" 
          integrity="sha384-..." crossorigin="anonymous"></script>
  ```

---

## 三、正面评价 (亮点)

### ✅ 做得好的地方

1. **使用 Flask-WTF 表单验证** (`forms.py`) - 对输入进行了基本验证
2. **使用 SQLAlchemy ORM** - 避免了大部分 SQL 注入风险
3. **文件上传大小限制** (`app.py` 第 43 行) - `MAX_CONTENT_LENGTH = 10MB`
4. **使用 secure_filename** (`app.py` 第 288 行) - 防止路径遍历
5. **图片压缩功能** (`index.html` 第 48-83 行) - 前端压缩减少服务器压力
6. **索引优化** (`models.py` 第 503-504 行) - 为常用查询字段添加索引
7. **数据库连接池配置** (`app.py` 第 37-41 行) - 合理的池化设置
8. **分离性格系统配置** (`dog_personality.py`, `cat_personality.py`) - 业务逻辑与配置分离
9. **维护模式功能** - 允许管理员优雅地进行系统维护
10. **来源追踪** (`app.py` 第 75-80 行) - 支持营销渠道分析

---

## 四、修复优先级建议

### 第 1 阶段 (24 小时内 - P0)
1. 修改管理员密码为环境变量强制设置 + bcrypt 哈希
2. 生成新的 SECRET_KEY 并通过环境变量配置
3. 数据库凭证实移至环境变量
4. 启用 CSRF 保护
5. 加强文件上传验证 (MIME 类型检查)

### 第 2 阶段 (1 周内 - P1)
1. 修复会话固定攻击 (登录后重新生成会话)
2. 对 Markdown 输出进行 HTML 清理
3. 移除调试模式或添加环境检查
4. 添加速率限制 (特别是登录端点)
5. 配置日志脱敏
6. 添加密码强度验证

### 第 3 阶段 (1 月内 - P2)
1. 修复 `created_at` 重复定义
2. 将分数字段改为 JSON 类型
3. 统一时区处理逻辑
4. 添加文件锁机制
5. 完善错误处理和用户提示

### 第 4 阶段 (持续优化 - P3)
1. 消除代码重复
2. 提取魔法数字为常量
3. 添加 API 版本控制
4. 添加 CDN 资源完整性校验
5. 前端资源压缩构建

---

## 五、架构改进建议

### 短期 (1-3 个月)
1. **配置管理**: 使用 `.env` 文件或专门的配置模块管理所有敏感配置
2. **蓝本分离**: 将管理员功能移至独立的 Blueprint
3. **API 规范化**: 统一 API 响应格式，添加版本控制

### 中期 (3-6 个月)
1. **用户系统**: 添加完整的用户注册/登录系统 (而非单一管理员密码)
2. **缓存层**: 引入 Redis 缓存性格描述等静态数据
3. **异步任务**: 使用 Celery 处理图片压缩、报告生成等耗时操作

### 长期 (6-12 个月)
1. **微服务拆分**: 将评估引擎、报告生成、用户管理拆分为独立服务
2. **容器化**: 使用 Docker 部署，便于扩展和管理
3. **CI/CD**: 建立自动化测试和部署流程

---

## 六、安全加固检查清单

- [ ] 所有硬编码凭证实移至环境变量
- [ ] 启用 HTTPS (宝塔面板配置 SSL)
- [ ] 配置 CSP (Content Security Policy) 响应头
- [ ] 添加安全响应头 (X-Frame-Options, X-Content-Type-Options 等)
- [ ] 定期更新依赖包 (Flask, SQLAlchemy 等)
- [ ] 配置防火墙限制数据库端口访问
- [ ] 启用数据库审计日志
- [ ] 定期进行安全扫描 (使用 Bandit, Safety 等工具)

---

**报告生成**: Hermes Agent 安全审计系统  
**审计工具**: 静态代码分析 + 人工审查  
**下次审计建议**: 修复 P0/P1 问题后重新审计
