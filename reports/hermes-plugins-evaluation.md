# Hermes Agent 插件生产部署评估报告

**评估对象**: 5 个 Hermes Agent 插件  
**用户环境**: 
- 两台 VPS：ENTH（香港，540MB 空闲内存）+ DW（大陆，2GB 空闲内存，网络受限）
- API 提供商：DeepSeek（¥1-2/M tokens）
- 交互方式：微信机器人
- 定时任务：9 个 cron jobs
- 优先级：可靠性 > 功能性 > 用户体验

---

## 1. disk-cleanup (bundled) ⭐⭐⭐⭐⭐

### 功能说明
自动追踪和清理 Hermes 会话期间产生的临时文件：
- **test 文件**: 会话结束时立即删除
- **temp 文件**: 7 天后删除
- **cron-output**: 14 天后删除
- **空目录**: 始终删除（在 HERMES_HOME 下）
- 范围严格限制在 `HERMES_HOME` 和 `/tmp/hermes-*`

### 安装难度
**极简** - 内置插件，只需执行：
```bash
hermes plugins enable disk-cleanup
```
无需额外依赖，纯 Python 实现。

### 资源消耗
- **内存**: <5MB（仅在会话结束时激活）
- **CPU**: 可忽略（仅在文件写入时扫描路径）
- **磁盘 I/O**: 低（仅维护一个 tracked.json 状态文件）

### 稳定性风险
**极低**：
- 只删除明确追踪的文件
- 有完善的日志记录（`disk-cleanup/cleanup.log`）
- 安全路径检查防止误删系统文件
- 操作原子化，有备份机制

### 对该用户的价值
**极高**：
- ✅ 用户有 9 个 cron jobs，会产生大量 cron-output 文件
- ✅ 两台服务器磁盘空间都需要有效管理
- ✅ 大陆服务器网络受限，本地清理比上传云存储更可靠
- ✅ 微信交互场景下，用户无法手动清理，自动化至关重要

### 推荐指数：⭐⭐⭐⭐⭐ (5/5)
**强烈建议启用** - 这是生产部署的必备插件，几乎零成本，高回报。

---

## 2. security-guidance (bundled) ⭐⭐⭐

### 功能说明
在文件写入时检测危险代码模式并附加安全警告：
- 检测模式：`eval()`, `pickle.load`, `yaml.load`, `os.system`, `subprocess(shell=True)` 等 25+ 规则
- **非阻塞模式**（默认）：文件仍会写入，警告在下一轮对话中显示给模型
- **阻塞模式**（可选）：设置 `SECURITY_GUIDANCE_BLOCK=1` 可拒绝写入

### 安装难度
**极简** - 内置插件：
```bash
hermes plugins enable security-guidance
```
无需额外依赖。

### 资源消耗
- **内存**: <10MB（预编译正则表达式）
- **CPU**: 低（仅扫描写入内容，有 256KB 上限）
- **延迟**: 可忽略（模式匹配在毫秒级）

### 稳定性风险
**低**：
- 默认非阻塞，不会中断工作流
- 有假阳性可能（如 `eval(` 在 tokenizer 代码中）
- 可通过 `SECURITY_GUIDANCE_DISABLE=1` 临时禁用

### 对该用户的价值
**中等**：
- ⚠️ 用户是建筑公司，主要处理设计文档而非危险代码
- ⚠️ 微信机器人交互场景下，安全警告可能增加对话轮数
- ✅ 如果 Hermes 用于生成/修改生产代码，有一定价值
- ⚠️ 大陆服务器上的代码如果有特殊需求，警告可能成为干扰

### 推荐指数：⭐⭐⭐ (3/5)
**可选启用** - 如果 Hermes 主要用于代码相关工作则启用，否则可跳过。

---

## 3. web/ddgs (bundled) ⭐⭐

### 功能说明
通过 `ddgs` Python 包实现 DuckDuckGo 网页搜索：
- 无需 API key
- 通过 scraping DDG HTML 结果页工作
- 仅支持搜索，不支持内容提取

### 安装难度
**中等** - 需要安装依赖：
```bash
hermes plugins enable web/ddgs
# 首次使用时会自动 pip install ddgs
```
已确认 `ddgs` 包已安装在系统中（v9.14.4）。

### 资源消耗
- **内存**: ~20MB（ddgs 库 + httpx + lxml）
- **CPU**: 中等（HTML 解析）
- **网络**: 每次搜索需要访问 DuckDuckGo

### 稳定性风险
**中等**：
- ⚠️ **大陆服务器网络问题**: DuckDuckGo 在中国大陆可能被屏蔽或限速
- ⚠️ DDG 可能改变 HTML 结构导致解析失败
- ⚠️ 无官方 API，稳定性依赖第三方 scraping
- ⚠️ 有速率限制（服务器端 enforced）

### 对该用户的价值
**较低**：
- ❌ 大陆服务器 (DW) 可能无法访问 DuckDuckGo
- ⚠️ 香港服务器 (ENTH) 可以访问，但 540MB 内存紧张
- ❌ 微信机器人场景下，搜索功能使用频率可能不高
- ⚠️ 建筑公司业务场景对实时网页搜索需求有限

### 推荐指数：⭐⭐ (2/5)
**不建议启用** - 网络限制和内存约束使其实用价值有限。如果确实需要搜索功能，考虑自建的 SearXNG 实例。

---

## 4. observability/langfuse (bundled) ⭐

### 功能说明
将 Hermes 对话、LLM 调用和工具使用追踪到 Langfuse 平台：
- 记录完整的对话轨迹
- 追踪 token 使用和成本
- 支持采样率和数据截断
- 需要 Langfuse 云账户或自建实例

### 安装难度
**较高** - 需要：
```bash
pip install langfuse
# 配置环境变量
HERMES_LANGFUSE_PUBLIC_KEY=pk-lf-xxx
HERMES_LANGFUSE_SECRET_KEY=sk-lf-...
```

### 资源消耗
- **内存**: ~50-100MB（Langfuse SDK + 缓冲队列）
- **CPU**: 低（后台异步发送）
- **网络**: 持续 outbound 连接到 Langfuse 服务器
- **延迟**: 可能增加（SDK 初始化 + 数据发送）

### 稳定性风险
**中等**：
- ⚠️ 依赖外部服务（Langfuse Cloud 或自建）
- ⚠️ 大陆服务器访问 Langfuse Cloud 可能受限
- ⚠️ SDK 初始化失败可能导致插件静默失效
- ⚠️ 内存占用对 ENTH 服务器（540MB 空闲）有压力

### 对该用户的价值
**低**：
- ❌ DeepSeek API 已经非常便宜（¥1-2/M tokens），成本追踪价值有限
- ❌ 微信机器人场景下，调试主要通过日志而非 dashboard
- ❌ 需要浏览器访问 dashboard，与用户工作流不符
- ❌ 大陆服务器网络问题可能导致数据丢失
- ⚠️ 内存消耗对资源紧张的服务器不友好

### 推荐指数：⭐ (1/5)
**不建议启用** - 成本高（内存 + 网络 + 配置复杂度），收益低（用户已有廉价 API + 微信交互）。Hermes 内置的 `agent.log` 和 `hermes logs` 命令已足够调试。

---

## 5. memory/holographic (社区高价值插件) ⭐⭐⭐⭐

### 功能说明
本地结构化记忆存储，使用 SQLite + 混合检索：
- **实体解析**: 自动识别和关联人名、项目名等实体
- **信任评分**: 事实有 0-1 信任度，可反馈调整
- **混合检索**: FTS5 全文搜索 + Jaccard 相似度 + HRR 向量检索
- **完全本地**: 无需外部 API，数据存储在 `memory_store.db`

### 安装难度
**极简** - 内置插件：
```bash
hermes plugins enable memory/holographic
```
无需额外依赖（numpy 可选，用于 HRR 向量检索）。

### 资源消耗
- **内存**: ~15-30MB（SQLite + 检索引擎）
- **CPU**: 低（检索时激活）
- **磁盘**: 取决于记忆数量（通常 <10MB）

### 稳定性风险
**低**：
- ✅ 纯本地运行，无网络依赖
- ✅ SQLite 成熟稳定
- ✅ 无外部 API 依赖
- ⚠️ 大量记忆时检索可能变慢（但用户场景不太可能达到）

### 对该用户的价值
**高**：
- ✅ **完全本地**: 两台服务器都能稳定运行，不受网络限制
- ✅ **跨会话记忆**: 微信机器人可以记住用户偏好、项目信息
- ✅ **低资源消耗**: 对 540MB 空闲内存的 ENTH 友好
- ✅ **建筑业务场景**: 可以存储客户偏好、项目规范、材料选择等
- ✅ **无需额外配置**: 启用即可使用

### 推荐指数：⭐⭐⭐⭐ (4/5)
**建议启用** - 最符合用户需求的记忆插件，本地运行、低资源、高价值。

---

## 总结与建议

| 插件 | 评分 | 建议 | 关键原因 |
|------|------|------|----------|
| disk-cleanup | ⭐⭐⭐⭐⭐ | **必须启用** | 9 个 cron jobs 产生大量临时文件，自动化清理必不可少 |
| security-guidance | ⭐⭐⭐ | 可选 | 建筑公司业务场景代码风险低，假阳性可能干扰 |
| web/ddgs | ⭐⭐ | 不启用 | 大陆网络限制 + 内存紧张 + 使用场景有限 |
| langfuse | ⭐ | 不启用 | 高成本低收益，DeepSeek 已很便宜，内置日志足够 |
| memory/holographic | ⭐⭐⭐⭐ | **建议启用** | 本地运行、跨会话记忆、低资源消耗 |

### 最终推荐配置

**在两台服务器上都启用**:
```bash
hermes plugins enable disk-cleanup
hermes plugins enable memory/holographic
```

**可选**（仅在 ENTH 香港服务器）:
```bash
# 如果确实需要网页搜索功能
hermes plugins enable web/ddgs
```

**不建议启用**:
- `security-guidance` - 除非 Hermes 频繁生成/修改生产代码
- `langfuse` - 成本高，收益低，与用户工作流不匹配

### 额外建议

1. **监控内存使用**: ENTH 服务器只有 540MB 空闲，启用插件后观察 `hermes logs --follow`
2. **大陆服务器网络**: DW 服务器的任何 outbound 连接都可能受限，优先选择本地运行的插件
3. **微信消息限制**: 系统已自动处理长消息归档（坚果云），无需额外插件
4. **定期清理**: 即使启用了 disk-cleanup，建议每月手动检查 `hermes disk-cleanup status`
