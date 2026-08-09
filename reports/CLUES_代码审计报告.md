# CLUES 宠物性格评估系统 - 完整代码审计报告

**审计日期**: 2026-06-07  
**审计范围**: 全栈代码 + 数据库  
**项目路径**: `/www/wwwroot/clues/clues_website/`  
**数据库**: MySQL `clues_db` (398 条记录)

---

## 📊 综合评分概览

| 审计维度 | 评分 (1-10) | 权重 | 加权分 |
|---------|------------|------|--------|
| 代码质量 | 6.5 | 20% | 1.30 |
| 安全性 | 4.0 | 25% | 1.00 |
| 架构设计 | 5.5 | 15% | 0.83 |
| 数据库设计 | 6.0 | 15% | 0.90 |
| 业务逻辑 | 7.0 | 15% | 1.05 |
| 前端实现 | 6.5 | 10% | 0.65 |
| **综合评分** | | **100%** | **5.73/10** |

**评级**: ⚠️ **中等风险** - 需要优先修复安全问题

---

## 1. 代码质量审计 (评分: 6.5/10)

### 1.1 app.py (489 行) - 主应用文件

#### ✅ 优点
- 代码结构清晰，路由定义有序
- 使用了 Flask 最佳实践（蓝图装饰器、session 管理）
- 有基本的日志记录 (`logging.basicConfig`)
- 维护模式功能设计合理（JSON 文件存储状态）

#### ❌ 问题发现

| 行号 | 问题类型 | 描述 | 严重性 |
|------|---------|------|--------|
| 20 | 硬编码密码 | `ADMIN_PASSWORD` 明文写在代码中 | 🔴 高 |
| 33 | 硬编码密钥 | `SECRET_KEY = 'darrin-wong-20260501'` 可预测 | 🔴 高 |
| 34 | 硬编码凭据 | 数据库密码被隐藏但仍在代码中 | 🔴 高 |
| 135-136 | 未使用的变量 | `DESC_CACHE = {}` 定义后从未使用 | 🟡 低 |
| 319-353 | 代码重复 | `build_result_context` 调用逻辑重复 | 🟡 中 |
| 382-383 | 默认值硬编码 | 分数缺失时补全 `[3]*25`，应配置化 | 🟡 低 |
| 425-432 | 装饰器位置 | `admin_required` 定义在路由之后，应移至文件顶部 | 🟢 低 |

#### 📝 建议
```python
# 修复示例：使用环境变量
import os
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', os.urandom(32).hex())
ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
```

### 1.2 models.py (45 行) - ORM 模型

#### ✅ 优点
- 使用了 SQLAlchemy ORM，避免原生 SQL
- 定义了适当的索引
- 有中文注释说明字段用途

#### ❌ 问题发现

| 行号 | 问题类型 | 描述 | 严重性 |
|------|---------|------|--------|
| 37, 43 | 字段重复定义 | `created_at` 被定义两次，第二次覆盖第一次 | 🟡 中 |
| 24-29 | 反模式设计 | 分数存储为逗号分隔字符串，违反第一范式 | 🟡 中 |
| 11-15 | 索引命名 | 索引命名不规范，缺少前缀 | 🟢 低 |

#### 📝 建议
```python
# 修复重复定义
created_at = db.Column(db.DateTime, default=lambda: datetime.now(CHINA_TZ), comment='创建时间')

# 规范化分数存储（可选，需重构）
# 方案 A: JSON 类型 (MySQL 5.7+)
scores = db.Column(db.JSON, nullable=True, comment='25 题分数数组')
# 方案 B: 独立关联表
class PetScore(db.Model):
    assessment_id = db.Column(db.Integer, db.ForeignKey('pet_assessment.id'))
    question_num = db.Column(db.Integer)
    score = db.Column(db.Integer)
```

### 1.3 forms.py (11 行) - WTForms 表单

#### ✅ 优点
- 使用了 WTForms 进行表单验证
- 有适当的验证器（DataRequired, NumberRange, FileAllowed）

#### ❌ 问题发现
- 缺少 CSRF 保护配置（虽然 Flask-WTF 默认启用，但未显式配置）
- 年龄验证范围 0-30 年对于宠物可能过大（猫狗极少超过 20 年）

### 1.4 cat_personality.py & dog_personality.py (各约 48 行)

#### ✅ 优点
- 数据结构清晰，使用字典映射
- 猫狗各有 32 种性格类型（5 维 × 2^5 = 32），覆盖完整
- 途径（pathway）设计有创意（月亮/命运/幽影/魔女 vs 猎人/战士/旅行家/黑夜）

#### ❌ 问题发现
- 硬编码数据结构，难以动态扩展
- 缺少数据验证（无校验代码格式是否为 5 位）

### 1.5 generate_descriptions.py (103 行)

#### ✅ 优点
- 自动生成 64 个 Markdown 描述文件（32 狗 + 32 猫）
- 模板化内容结构清晰

#### ❌ 问题发现
- 仅生成模板内容，实际描述需要手动填写
- 缺少增量更新机制（每次运行都覆盖）

### 1.6 gunicorn_conf.py (36 行)

#### ✅ 优点
- 配置了适当的 worker 数量 (4) 和线程数 (2)
- 有访问日志和错误日志配置
- PID 文件配置便于进程管理

#### ❌ 问题发现

| 行号 | 问题 | 建议 |
|------|------|------|
| 17 | 端口 333 是特权端口以下，可能需要 root | 考虑使用 8000+ 端口 |
| 23 | 日志路径拼写错误 `gunicorn_acess.log` → `access` | 修复拼写 |
| 5-8 | worker 配置固定，应基于 CPU 核心数动态计算 | `workers = multiprocessing.cpu_count() * 2 + 1` |

---

## 2. 安全性审计 (评分: 4.0/10) 🔴

### 2.1 认证与授权

| 问题 | 位置 | 风险等级 | 描述 |
|------|------|---------|------|
| 明文管理员密码 | app.py:20 | 🔴 高危 | `ADMIN_PASSWORD = 'RaDe4321'` 硬编码 |
| 可预测的 SECRET_KEY | app.py:33 | 🔴 高危 | 包含日期，易被猜测 |
| 无密码加密 | app.py:438 | 🔴 高危 | 直接字符串比较，无哈希 |
| 无登录失败限制 | app.py:434-443 | 🟡 中危 | 可暴力破解 |
| 无会话超时 | app.py:445-448 | 🟡 中危 | 管理员会话永不过期 |

#### 📝 修复建议
```python
# 使用 werkzeug 进行密码哈希
from werkzeug.security import generate_password_hash, check_password_hash

# 初始化时
ADMIN_PASSWORD_HASH = generate_password_hash(os.environ.get('ADMIN_PASSWORD'))

# 验证时
if check_password_hash(ADMIN_PASSWORD_HASH, password):
    session['admin_logged_in'] = True
```

### 2.2 SQL 注入风险

| 评估项 | 状态 | 说明 |
|--------|------|------|
| ORM 使用 | ✅ 安全 | 全程使用 SQLAlchemy ORM |
| 原生 SQL | ✅ 无 | 未发现原生 SQL 查询 |
| 参数化查询 | ✅ 安全 | filter_by 使用参数化 |

**结论**: SQL 注入风险低，ORM 使用正确。

### 2.3 XSS (跨站脚本攻击)

| 位置 | 问题 | 风险等级 |
|------|------|---------|
| result.html:96 | `{{ full_description|safe }}` | 🔴 高危 |
| admin.html:47-53 | 直接输出用户数据 | 🟡 中危 |
| quiz.html:319 | PET_NAME 直接注入 JS | 🟡 中危 |

#### 📝 详细说明

**result.html 第 96 行**:
```jinja2
{{ full_description|safe }}
```
使用 `|safe` 过滤器会禁用 HTML 转义，如果 Markdown 文件被篡改注入恶意脚本，将导致 XSS。

**quiz.html 第 200-201 行**:
```javascript
const PET_NAME = "{{ pet_name }}";
const PET_AVATAR = "{{ pet_avatar }}";
```
如果 `pet_name` 包含 `"; alert('XSS'); //` 等恶意内容，将导致 XSS。

#### 📝 修复建议
```jinja2
{# 移除 |safe，使用 bleach 清理 HTML #}
{{ full_description }}

{# 或在后端处理 #}
import bleach
full_description = bleach.clean(markdown.markdown(md_content))
```

```javascript
{# Jinja2 模板中 #}
const PET_NAME = {{ pet_name|tojson }};
const PET_AVATAR = {{ pet_avatar|tojson }};
```

### 2.4 CSRF 保护

| 评估项 | 状态 |
|--------|------|
| Flask-WTF CSRF | ⚠️ 未显式启用 |
| 表单 CSRF Token | ❌ 未发现 |
| AJAX CSRF | ❌ feedback 接口无保护 |

#### 📝 修复建议
```python
# app.py
app.config['WTF_CSRF_ENABLED'] = True
app.config['WTF_CSRF_SECRET_KEY'] = os.environ.get('CSRF_KEY', os.urandom(32).hex())

# forms.py
class PetInfoForm(FlaskForm):
    # 自动包含 CSRF token
    ...
```

### 2.5 文件上传安全

| 评估项 | 状态 | 说明 |
|--------|------|------|
| 文件类型限制 | ✅ 已实现 | 只允许 png/jpg/jpeg/gif |
| 文件名清理 | ✅ 已实现 | 使用 `secure_filename()` |
| UUID 重命名 | ✅ 已实现 | 防止文件名冲突 |
| 文件大小限制 | ✅ 已实现 | `MAX_CONTENT_LENGTH = 10MB` |
| 文件内容验证 | ❌ 缺失 | 未检查文件魔数 |

#### 📝 建议增强
```python
import imghdr

def allowed_file(filename, file_stream):
    # 检查扩展名
    if '.' not in filename:
        return False
    ext = filename.rsplit('.', 1)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        return False
    # 检查文件魔数
    file_stream.seek(0)
    return imghdr.what(file_stream) in ['png', 'jpeg', 'gif']
```

### 2.6 其他安全问题

| 问题 | 风险等级 | 描述 |
|------|---------|------|
| 调试模式可能开启 | 🟡 中 | `app.run(debug=True)` 在生产环境危险 |
| 错误信息泄露 | 🟡 中 | 未配置自定义错误页面 |
| 无 HTTPS 强制 | 🟡 中 | 未配置 HSTS |
| 无速率限制 | 🟡 中 | API 接口可被滥用 |
| Session 配置薄弱 | 🟡 中 | 无会话超时、无安全标志 |

---

## 3. 架构设计审计 (评分: 5.5/10)

### 3.1 分层结构

```
当前架构:
┌─────────────────────────────────────┐
│           app.py (489 行)            │
│  ┌─────────────────────────────┐    │
│  │ 路由 + 业务逻辑 + 数据库操作 │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│         models.py (ORM)             │
│         forms.py (WTForms)          │
│    cat/dog_personality.py           │
│    generate_descriptions.py         │
└─────────────────────────────────────┘
```

#### ❌ 问题
- **胖模型反模式**: `app.py` 承载过多职责（路由 + 业务 + 数据访问）
- **缺少服务层**: 无独立的业务逻辑层
- **缺少 API 层**: 前后端耦合，无 RESTful API

#### 📝 建议架构
```
建议架构:
┌─────────────────────────────────────┐
│          routes/ (蓝图)              │
│   ┌─────────┬─────────┬─────────┐   │
│   │ main.py │ admin.py│ api.py  │   │
│   └─────────┴─────────┴─────────┘   │
├─────────────────────────────────────┤
│         services/ (业务逻辑)         │
│  ┌──────────┬──────────┬─────────┐  │
│  │assessment│ report  │ feedback│  │
│  └──────────┴──────────┴─────────┘  │
├─────────────────────────────────────┤
│         models/ (数据访问)           │
│         forms/ (表单验证)            │
│    personalities/ (性格配置)         │
└─────────────────────────────────────┘
```

### 3.2 可扩展性

| 评估项 | 状态 | 说明 |
|--------|------|------|
| 多物种支持 | ✅ 良好 | 猫狗架构一致，易扩展 |
| 配置外部化 | ❌ 差 | 密钥、密码硬编码 |
| 插件机制 | ❌ 无 | 无法动态添加性格维度 |
| 国际化 | ❌ 无 | 硬编码中文 |

### 3.3 代码复用

| 问题 | 位置 | 建议 |
|------|------|------|
| 维度分数分割重复 | app.py:179-183, 320-324 | 提取为工具函数 |
| 物种判断重复 | app.py 多处 | 使用策略模式 |
| 描述加载逻辑 | 仅一处 | 可添加缓存装饰器 |

---

## 4. 数据库设计审计 (评分: 6.0/10)

### 4.1 Schema 设计

```sql
CREATE TABLE pet_assessment (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pet_name VARCHAR(50) NOT NULL,
    pet_species VARCHAR(10) NOT NULL,  -- 'dog' / 'cat'
    pet_breed VARCHAR(50),
    pet_age INT,                        -- 月
    pet_avatar VARCHAR(200),
    
    -- 分数存储（反模式）
    scores_social VARCHAR(20),          -- '4,5,3,4,5'
    scores_explore VARCHAR(20),
    scores_cooperate VARCHAR(20),
    scores_emotion VARCHAR(20),
    scores_vitality VARCHAR(20),
    
    -- 结果
    clue_code VARCHAR(10),
    clue_role VARCHAR(50),
    clue_slogan VARCHAR(100),
    has_x BOOLEAN DEFAULT FALSE,
    
    -- 元数据
    created_at DATETIME,
    channel VARCHAR(50),
    like_count INT DEFAULT 0,
    dislike_count INT DEFAULT 0,
    
    INDEX idx_species_code (pet_species, clue_code),
    INDEX idx_created_at (created_at)
);
```

### 4.2 索引分析

| 索引名 | 列 | 类型 | 评估 |
|--------|-----|------|------|
| PRIMARY | id | BTREE | ✅ 必要 |
| idx_species_code | pet_species, clue_code | BTREE | ✅ 合理 |
| idx_created_at | created_at | BTREE | ✅ 合理 |

**建议新增索引**:
```sql
-- 按渠道统计
CREATE INDEX idx_channel ON pet_assessment(channel);
-- 按点赞排序
CREATE INDEX idx_like_count ON pet_assessment(like_count DESC);
```

### 4.3 数据质量问题

#### 发现的问题

| 问题 | 数量 | 占比 | 说明 |
|------|------|------|------|
| 包含 'X' 的无效代码 | 3 | 0.75% | 旧版本遗留数据 |
| 分数维度不一致 | 未知 | - | 部分记录 4 个分数，部分 5 个 |
| channel 全为 NULL | 398 | 100% | 来源追踪未启用 |

#### 数据分布

```
物种分布:
┌─────────┬───────┬────────┐
│ Species │ Count │ Ratio  │
├─────────┼───────┼────────┤
│ dog     │ 369   │ 92.7%  │
│ cat     │ 29    │ 7.3%   │
└─────────┴───────┴────────┘

CLUE 代码 Top 10:
┌─────────┬───────┬────────┐
│ Code    │ Count │ Ratio  │
├─────────┼───────┼────────┤
│ EAORV   │ 155   │ 39.0%  │
│ EAORQ   │ 53    │ 13.3%  │
│ EAPRV   │ 44    │ 11.1%  │
│ EAPRQ   │ 28    │ 7.0%   │
│ EAOSV   │ 14    │ 3.5%   │
│ ECORQ   │ 13    │ 3.3%   │
│ EAPSV   │ 8     │ 2.0%   │
│ EAPSQ   │ 8     │ 2.0%   │
│ ECORV   │ 8     │ 2.0%   │
│ ECPSQ   │ 8     │ 2.0%   │
└─────────┴───────┴────────┘
```

**观察**: 
- 狗用户远多于猫用户（92.7% vs 7.3%）
- EAORV（火箭/社交探险家）占比近 40%，可能问卷设计有偏差
- 数据分布呈现长尾，符合预期

### 4.4 字段类型建议

| 字段 | 当前类型 | 建议类型 | 理由 |
|------|---------|---------|------|
| scores_* | VARCHAR(20) | VARCHAR(25) | 5 个分数最多 25 字符 |
| clue_code | VARCHAR(10) | CHAR(5) | 固定 5 位，节省空间 |
| created_at | DATETIME | TIMESTAMP | 自动时区转换 |
| like/dislike_count | INT | SMALLINT | 不会超过 32767 |

---

## 5. 业务逻辑审计 (评分: 7.0/10)

### 5.1 CLUE 分数算法

```python
def compute_dimension(scores_list, high_letter, low_letter):
    t = 0
    total = 0
    for s in scores_list:
        total += s
        if s >= 4:
            t += 1
        elif s <= 2:
            t -= 1
    if t > 0:
        return high_letter
    elif t < 0:
        return low_letter
    else:
        return high_letter if total >= 15 else low_letter
```

#### ✅ 优点
- 投票机制 + 总分破平局，逻辑清晰
- 考虑了极端值（1-2 分 vs 4-5 分）
- 平局时倾向高分（>=15 分）

#### ❌ 问题
- 阈值硬编码（4 分、2 分、15 分）
- 3 分（中立）完全被忽略
- 无边界情况处理（空列表）

#### 📝 建议
```python
THRESHOLD_HIGH = 4
THRESHOLD_LOW = 2
NEUTRAL_SCORE = 3

def compute_dimension(scores_list, high_letter, low_letter):
    if not scores_list:
        return high_letter  # 或抛出异常
    
    t = sum(1 if s >= THRESHOLD_HIGH else -1 if s <= THRESHOLD_LOW else 0 
            for s in scores_list)
    total = sum(scores_list)
    avg = total / len(scores_list)
    
    if t > 0:
        return high_letter
    elif t < 0:
        return low_letter
    else:
        return high_letter if avg >= NEUTRAL_SCORE else low_letter
```

### 5.2 性格类型映射

| 维度 | 字母 | 含义 | 对立 |
|------|------|------|------|
| 社交倾向 | E/I | Enthusiastic/Independent | 热情/独立 |
| 探索能级 | A/C | Adventurous/Cautious | 冒险/谨慎 |
| 配合状态 | O/P | Obedient/Persistent | 服从/固执 |
| 情绪特征 | R/S | Resilient/Sensitive | 镇定/敏感 |
| 活力水平 | V/Q | Vigorous/Quiet | 活力/安静 |

**组合数**: 2^5 = 32 种类型 ✅

### 5.3 数据一致性

| 检查项 | 状态 | 说明 |
|--------|------|------|
| clue_code 与 clue_role 一致 | ✅ | 从同一系统获取 |
| 分数与代码一致 | ⚠️ | 3 条记录代码含 'X' |
| 记录可追溯 | ✅ | 有 created_at 和 channel |

---

## 6. 前端审计 (评分: 6.5/10)

### 6.1 模板结构

```
templates/
├── base.html          # 基础模板
├── index.html         # 首页（宠物信息录入）
├── quiz.html          # 问卷页面
├── result.html        # 结果页面
├── admin.html         # 管理后台
├── admin_login.html   # 管理员登录
├── admin_maintenance.html  # 维护模式
└── maintenance.html   # 维护中页面
```

### 6.2 表单验证

| 验证类型 | 前端 | 后端 | 评估 |
|---------|------|------|------|
| 必填字段 | ✅ | ✅ | 双重验证 |
| 数字范围 | ✅ | ❌ | 仅前端验证 |
| 文件类型 | ✅ | ✅ | 双重验证 |
| CSRF Token | ❌ | ❌ | 缺失 |

### 6.3 用户体验

#### ✅ 优点
- 响应式设计（Bootstrap 5）
- 进度条显示
- 维度导航高亮
- 宠物头像个性化
- 雷达图可视化（Chart.js）
- 报告截图功能（html2canvas）
- 分享二维码（qrcodejs）

#### ❌ 问题
- 问卷无法中途保存
- 无题目预览/回顾功能
- 错误提示不够友好
- 移动端触摸体验待优化

### 6.4 JavaScript 安全

| 问题 | 位置 | 风险 |
|------|------|------|
| innerHTML 使用 | quiz.html:330 | XSS 风险 |
| 用户数据直接注入 | quiz.html:200-201 | XSS 风险 |
| 无 CSP 头 | 全局 | XSS 风险 |

---

## 7. 部署与运维审计 (评分: 6.0/10)

### 7.1 Gunicorn 配置

| 配置项 | 当前值 | 建议 |
|--------|--------|------|
| workers | 4 | `cpu_count * 2 + 1` |
| threads | 2 | ✅ 合理 |
| bind | 0.0.0.0:333 | 考虑 8000+ 端口 |
| loglevel | info | ✅ 合理 |
| accesslog | 有拼写错误 | 修复 `acess` → `access` |

### 7.2 日志配置

| 评估项 | 状态 |
|--------|------|
| 应用日志 | ⚠️ 仅 INFO 级别 |
| 访问日志 | ✅ 已配置 |
| 错误日志 | ✅ 已配置 |
| 日志轮转 | ❌ 未配置 |
| 敏感信息脱敏 | ❌ 未实现 |

### 7.3 异常处理

| 位置 | 状态 | 说明 |
|------|------|------|
| 数据库操作 | ⚠️ 部分捕获 | 无统一异常处理 |
| 文件操作 | ✅ 已捕获 | try-except 包裹 |
| 全局异常 | ❌ 缺失 | 无 500 错误页面 |

#### 📝 建议
```python
@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    logger.error(f'Internal error: {error}')
    return render_template('500.html'), 500

@app.errorhandler(404)
def not_found(error):
    return render_template('404.html'), 404
```

### 7.4 维护模式

| 评估项 | 状态 |
|--------|------|
| 文件存储状态 | ✅ maintenance.json |
| 白名单路由 | ✅ 允许管理员访问 |
| 结束时间显示 | ✅ 用户友好 |
| 自动关闭 | ❌ 需手动关闭 |

---

## 8. 修复建议优先级

### 🔴 P0 - 立即修复（高危）

| # | 问题 | 影响 | 修复难度 |
|---|------|------|---------|
| 1 | 硬编码管理员密码 | 账户泄露 | 低 |
| 2 | 硬编码 SECRET_KEY | 会话劫持 | 低 |
| 3 | XSS 漏洞（|safe 过滤器） | 脚本注入 | 低 |
| 4 | 无 CSRF 保护 | 跨站请求伪造 | 中 |
| 5 | 明文密码比较 | 暴力破解 | 低 |

### 🟡 P1 - 尽快修复（中危）

| # | 问题 | 影响 | 修复难度 |
|---|------|------|---------|
| 1 | 登录失败无限制 | 暴力破解 | 中 |
| 2 | 会话无超时 | 会话劫持 | 低 |
| 3 | 文件上传无内容验证 | 恶意文件 | 中 |
| 4 | created_at 字段重复定义 | 数据不一致 | 低 |
| 5 | 分数存储反模式 | 查询困难 | 高 |

### 🟢 P2 - 建议修复（低危）

| # | 问题 | 影响 | 修复难度 |
|---|------|------|---------|
| 1 | 代码重复 | 维护困难 | 中 |
| 2 | 缺少服务层 | 架构混乱 | 高 |
| 3 | 日志无轮转 | 磁盘占用 | 低 |
| 4 | 无自定义错误页面 | 用户体验 | 低 |
| 5 | 索引不完整 | 查询性能 | 低 |

---

## 9. 总结

### 9.1 系统优势

1. **业务逻辑清晰**: CLUE 评估算法设计合理，32 种性格类型覆盖全面
2. **用户体验良好**: 响应式设计、可视化报告、分享功能完善
3. **数据完整性**: 398 条记录，数据质量总体良好
4. **扩展性基础**: 猫狗架构一致，易于扩展其他物种

### 9.2 主要风险

1. **安全风险突出**: 硬编码凭据、XSS、CSRF 等安全问题需优先修复
2. **架构耦合严重**: 489 行的 app.py 承载过多职责
3. **数据库反模式**: 逗号分隔字符串存储违反范式
4. **运维配置不足**: 日志、监控、异常处理不完善

### 9.3 修复路线图

```
第 1 周（安全加固）:
├─ 环境变量配置密钥和密码
├─ 添加密码哈希
├─ 修复 XSS 漏洞
└─ 启用 CSRF 保护

第 2 周（代码重构）:
├─ 拆分 app.py 为蓝图
├─ 添加服务层
└─ 修复重复代码

第 3 周（数据库优化）:
├─ 修复 created_at 重复定义
├─ 新增必要索引
└─ 数据清理（X 代码记录）

第 4 周（运维完善）:
├─ 配置日志轮转
├─ 添加错误页面
├─ 配置监控告警
└─ 压力测试
```

---

**审计人员**: Hermes Agent  
**报告生成时间**: 2026-06-07 03:52 UTC  
**下次审计建议**: 修复 P0 问题后重新审计
