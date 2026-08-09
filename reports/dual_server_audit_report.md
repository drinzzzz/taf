# 双服务器架构审计报告 (DW + ENTH)

**审计时间**: 2026-06-13 20:15 CST  
**审计范围**: DW(124.221.119.232) 上海腾讯云 + ENTH(43.154.76.118) 香港服务器  
**审计执行**: 全面系统检查、服务配置、安全策略、备份监控

---

## 一、执行摘要

### 整体评估
| 维度 | 评分 | 状态 |
|------|------|------|
| 服务分布 | ⚠️ 6/10 | 基本合理，存在单点故障风险 |
| 资源利用 | ⚠️ 5/10 | ENTH 内存严重不足，DW 相对健康 |
| 安全隔离 | ✅ 8/10 | SSH 互信配置正确，防火墙基本到位 |
| 故障转移 | ❌ 3/10 | 无自动故障转移机制 |
| 备份策略 | ❌ 4/10 | 数据库备份缺失，代码备份不完整 |
| 监控覆盖 | ✅ 7/10 | 健康检查脚本完善，告警机制缺失 |
| 数据流 | ⚠️ 6/10 | SSH 管道可靠但效率一般 |
| Cron 分布 | ✅ 8/10 | 定时任务分布合理 |

### 问题分级概览
- **P0 (紧急)**: 3 项
- **P1 (重要)**: 5 项
- **P2 (建议)**: 8 项

---

## 二、服务器基础信息

### DW (124.221.119.232) - 上海腾讯云
| 指标 | 数值 | 状态 |
|------|------|------|
| 运行时间 | 19 天 23 小时 | ✅ 稳定 |
| CPU | 4 核 | - |
| 内存 | 3.6GB 总量，已用 1.9GB (53%) | ✅ 健康 |
| 磁盘 | 40GB，已用 26GB (64%) | ⚠️ 需关注 |
| Swap | 1GB，已用 922MB (90%) | ⚠️ 偏高 |
| 负载 | 0.36/0.38/0.31 | ✅ 正常 |

### ENTH (43.154.76.118) - 香港
| 指标 | 数值 | 状态 |
|------|------|------|
| 运行时间 | 22 小时 | ✅ 新重启 |
| CPU | 2 核 | - |
| 内存 | 1.9GB 总量，已用 1.5GB (79%) | ❌ 紧张 |
| 磁盘 | 50GB，已用 19GB (38%) | ✅ 充足 |
| Swap | 1GB，已用 993MB (97%) | ❌ 几乎耗尽 |
| 负载 | 0.17/0.20/0.18 | ✅ 正常 |

---

## 三、服务分布审计

### DW 运行服务
| 服务 | 端口 | 状态 | 说明 |
|------|------|------|------|
| Hermes Gateway | 28790 (本地) | ❌ 异常重启 | 已运行 26891 次重启循环 |
| ProjectMate (Gunicorn) | 8000 | ✅ 运行中 | 4 worker，内存 375MB |
| WeChat Message Ingest API | 8501 | ✅ 运行中 | 消息接收服务 |
| MySQL | 3306 | ✅ 运行中 | 宝塔管理 |
| Nginx | 80/443/888 | ✅ 运行中 | 反代 + 面板 |
| Docker | - | ✅ 运行中 | containerd |

### ENTH 运行服务
| 服务 | 端口 | 状态 | 说明 |
|------|------|------|------|
| BookBaker | 8110 | ✅ 运行中 | Flask 后端 |
| SocialSeed | 8111 | ✅ 运行中 | API 服务 |
| CLUES Dev | 8001 / 333 | ✅ 运行中 | Gunicorn 5 worker |
| Console API | 8502 (本地) | ✅ 运行中 | Hermes Console |
| mailcow (Docker) | 25/465/587/993/995 等 | ✅ 运行中 | 18 个容器 |
| MySQL | 3306 | ✅ 运行中 | 宝塔管理 |
| PostgreSQL | 5432 (本地) | ✅ 运行中 | BookBaker/CLUES 使用 |
| MySQL Tunnel | 3307 (本地) | ✅ 运行中 | SSH 隧道到 DW:3306 |
| Nginx | 80/443/887/888 | ✅ 运行中 | 多域名反代 |

### 服务分布合理性分析

**✅ 合理之处**:
1. 外网服务全部在 ENTH（香港 IP，外网通畅）
2. 主控端 Hermes Gateway 在 DW（大陆，微信延迟低）
3. 邮件服务 mailcow 在 ENTH（需要外网 SMTP）
4. 数据库主实例在 DW，ENTH 通过 SSH 隧道访问

**⚠️ 问题**:
1. **单点故障**: MySQL 仅在 DW，DW 宕机则 ENTH 所有依赖数据库的服务不可用
2. **Gateway 异常**: DW 的 hermes-gateway 服务陷入重启循环（PID 冲突）
3. **资源错配**: ENTH 内存仅 2GB 却运行 mailcow(18 容器) + 多个 Python 服务

---

## 四、资源利用审计

### 内存使用详情

**DW 内存分布**:
- Hermes Gateway: 565MB (15%)
- ProjectMate Gunicorn: 450MB (4 worker)
- MySQL: 124MB
- 系统 + 其他: ~800MB

**ENTH 内存分布**:
- mailcow 容器组: ~800MB (42%)
- MariaDB (mailcow): 177MB
- Rspamd 进程组: ~300MB
- BookBaker/SocialSeed/CLUES: ~150MB
- 系统 + 其他: ~400MB

### 闲置算力分析

**DW**:
- CPU 使用率低（负载 0.36），有闲置算力
- 内存剩余 1.7GB 可用，可承载更多服务
- 带宽受限（腾讯云服务器）

**ENTH**:
- ❌ **内存严重不足**，swap 几乎用满
- CPU 使用率低，但受内存限制无法扩展
- 外网带宽充足，但算力被内存瓶颈限制

### 建议
1. **P0**: ENTH 需要扩容内存至 4GB 或迁移 mailcow 到独立服务器
2. **P1**: DW 可考虑承担更多计算任务（如坚果云扫描）

---

## 五、安全隔离审计

### SSH 密钥配置 ✅
```
DW authorized_keys:
- ssh-rsa (skey-cg5wscu3)
- ssh-ed25519 (root@VM-0-13-tencentos)
- ssh-ed25519 (drin@qq.com)

ENTH authorized_keys:
- from="124.221.119.232" ssh-rsa (skey-h6nspehl)
- from="124.221.119.232" ssh-ed25519 (drin@qq.com)
```
**评估**: ✅ 配置正确，ENTH 限制了来源 IP

### 防火墙规则

**ENTH firewalld**:
```
开放端口：20,21,22,80,443,8888,33477,39000-40000,888,9999,333,8001,8110,8111
服务：cockpit, dhcpv6-client, ssh
```
**评估**: ⚠️ 端口开放较多，建议审查必要性

**DW 宝塔防火墙**: 配置文件为空，依赖腾讯云安全组

### 数据库访问控制

**DW MySQL**:
- 端口 3306 监听所有接口（⚠️ 风险）
- 依赖腾讯云安全组限制外网访问

**ENTH MySQL**:
- 端口 3306 监听所有接口
- SSH 隧道 (3307) 仅监听本地

**建议**:
1. **P1**: MySQL 应仅监听 127.0.0.1，通过 SSH 隧道访问
2. **P2**: 审查 ENTH 开放端口，关闭不必要的服务

### 密钥管理 ⚠️
- SSH 私钥权限正确 (600)
- 坚果云凭证存储在脚本中（明文）
- 无集中式密钥管理系统

---

## 六、故障转移审计

### 当前故障转移能力

| 场景 | DW 宕机 | ENTH 宕机 |
|------|---------|-----------|
| ProjectMate | ❌ 不可用 | ✅ 正常 |
| Hermes Gateway | ❌ 不可用 | ⚠️ 部分功能 (cron 不执行) |
| BookBaker | ✅ 正常 | ❌ 不可用 |
| CLUES | ✅ 正常 | ❌ 不可用 |
| SocialSeed | ✅ 正常 | ❌ 不可用 |
| mailcow | ✅ 正常 | ❌ 不可用 |
| MySQL (DW) | ❌ 全部不可用 | ⚠️ 通过隧道不可用 |
| 坚果云扫描 | ⚠️ DW 扫描停摆 | ✅ ENTH 继续扫描 |

### 恢复能力

**自动恢复**:
- ✅ systemd 服务配置了 `Restart=on-failure`
- ✅ courier.sh 每分钟检查 gateway 状态
- ⚠️ Gateway 重启循环未设置最大重试次数

**手动恢复**:
- ✅ SSH 互信正常，可远程操作
- ✅ 健康检查脚本可快速诊断

### 建议
1. **P0**: 解决 Gateway 重启循环问题
2. **P1**: 考虑 MySQL 主从复制（ENTH 作为只读从库）
3. **P2**: 为关键服务配置健康检查 + 自动告警

---

## 七、备份策略审计

### 当前备份状态

**DW 备份**:
```
/www/backup/database/mysql/ - 空目录 ❌
/www/backup/site/ - 有配置但未见实际备份
```

**ENTH 备份**:
```
/www/backup/database/mysql/ - 有备份 ✅
/www/backup/database/pgsql/ - 有备份 ✅
/www/backup/site/ - 有网站备份 ✅
```

### 备份覆盖分析

| 数据类型 | DW 备份 | ENTH 备份 | 频率 |
|----------|---------|-----------|------|
| MySQL 数据库 | ❌ 无 | ✅ 有 | 未知 |
| PostgreSQL | N/A | ✅ 有 | 未知 |
| 代码 (ProjectMate) | ❌ 无 | N/A | - |
| 代码 (BookBaker/CLUES/SS) | N/A | ⚠️ 手动备份 | 不定期 |
| Hermes 配置 | ❌ 无 | ❌ 无 | - |
| Nginx 配置 | ⚠️ 宝塔自动 | ⚠️ 宝塔自动 | 未知 |
| 坚果云数据 | N/A | N/A | 云端 |

### 建议
1. **P0**: 立即配置 DW MySQL 自动备份（每日 + binlog）
2. **P1**: 配置代码仓库自动备份到坚果云/Git
3. **P1**: 配置 Hermes 配置备份（cron 列表、技能等）
4. **P2**: 测试备份恢复流程

---

## 八、监控覆盖审计

### 健康检查 ✅

**脚本位置**: `/root/.hermes/scripts/health_check.sh`

**检查项**:
- DW ProjectMate (HTTP 200)
- DW Root 重定向 (HTTP 301)
- ENTH CLUES Prod/Dev (HTTP 200)
- ENTH BookBaker (HTTP 200)
- ENTH SocialSeed (HTTP 200)
- ENTH Console (HTTP 200)
- DW→ENTH SSH 连通性
- ENTH→DW MySQL 隧道

**执行频率**: 每 5 分钟 (Hermes cron)

**问题**: 仅记录日志，无告警机制

### Cron 可靠性

**DW Hermes Cron**:
| 任务 | 调度 | 状态 | 最后执行 |
|------|------|------|----------|
| ProjectMate-早间日报 | 0 8 * * * | ⚠️ 发送限流 | 08:04 ✓ |
| ProjectMate-傍晚速报 | 0 18 * * * | ✅ | 18:01 ✓ |
| 坚果云每日扫描 | 15 8 * * * | ✅ | 08:17 ✓ |
| Hermes 进程清理 | 0 * * * * | ✅ | 20:00 ✓ |
| gunicorn watchdog | every 5m | ✅ | 20:08 ✓ |
| 订阅到期检查 | 0 9 * * * | ✅ | 09:00 ✓ |
| Gateway Guardian | every 2m | ✅ | 20:10 ✓ |
| 坚果云整点扫描 | 0 * * * * | ✅ | 20:00 ✓ |
| Health Check | every 5m | ✅ | 20:08 ✓ |

**ENTH Hermes Cron**:
| 任务 | 调度 | 状态 | 最后执行 |
|------|------|------|----------|
| BB 每日采集 | 0 4 * * * | ✅ | - |
| BB 学术研究 | 0 3 * * 2,4,6 | ✅ | - |
| BB 书稿复核 | 30 * * * * | ❌ API Key 无效 | 19:30 ✗ |
| BB 论文日报 | 5 8 * * * | ✅ | - |
| SocialSeed 每日 | 0 4 * * * | ✅ | - |
| CLUES 晚报 | 0 20 * * * | ❌ API Key 无效 | 20:00 ✗ |

**问题**:
1. ⚠️ 微信发送限流（早间日报）
2. ❌ ENTH Gateway 未运行，cron 不执行
3. ❌ API Key 失效导致多个任务失败

### 告警机制 ❌
- 无邮件/短信告警
- 无钉钉/企业微信 webhook
- 健康检查失败仅记录日志

### 建议
1. **P0**: 启动 ENTH Hermes Gateway
2. **P1**: 更新失效的 API Key
3. **P1**: 配置健康检查失败告警（邮件/webhook）
4. **P2**: 解决微信发送限流问题

---

## 九、数据流审计

### DW ↔ ENTH 数据交换

**当前方式**:
1. **SSH 管道**: `ssh enth "command"` 直接获取 JSON stdout
2. **SCP 文件**: ENTH 扫描坚果云 → scp JSON → DW 消费
3. **MySQL 隧道**: ENTH:3307 → SSH → DW:3306

**效率评估**:
- SSH 延迟: ~33ms (ping 测试)
- SCP 传输: 依赖文件大小，小文件 (<1MB) <1 秒
- MySQL 隧道: 稳定，未见延迟问题

**失败处理**:
- ⚠️ 无自动重试机制
- ⚠️ 无传输失败告警
- ✅ courier.sh 每分钟检查并消费新数据

### 坚果云扫描流程
```
ENTH (主力扫描) → 整点扫描 CURR_PRJ
    ↓ scp
DW (消费数据) → courier.sh 每分钟检查 → ProjectMate 处理
```

**问题**:
1. DW 也有整点扫描 cron（冗余）
2. 无扫描失败重试机制

### 建议
1. **P2**: 统一坚果云扫描到 ENTH，移除 DW 冗余扫描
2. **P2**: 配置 scp 失败重试和告警

---

## 十、Cron 分布审计

### 定时任务分布

**DW Cron** (系统 + Hermes):
- 日报推送 (8:00)
- 晚报推送 (18:00)
- 坚果云扫描 (8:15 + 整点)
- 健康检查 (每 5 分钟)
- Gateway 守护 (每 2 分钟)
- Gunicorn 守护 (每 5 分钟)

**ENTH Cron** (系统 + Hermes):
- BB 采集 (4:00)
- BB 学术研究 (3:00 周二/四/六)
- BB 书稿复核 (每 30 分钟)
- BB 论文日报 (8:05)
- SocialSeed 每日 (4:00)
- CLUES 晚报 (20:00)
- 坚果云批量扫描 (每 5 分钟)
- Hermes cron tick (每分钟)

### 分布合理性 ✅

**优点**:
1. 外网相关任务在 ENTH（BB 采集、SocialSeed）
2. 微信推送在 DW（大陆延迟低）
3. 健康检查双机都有

**优化建议**:
1. **P2**: 将 DW 坚果云整点扫描移除，由 ENTH 统一扫描
2. **P2**: 考虑将 BB 书稿复核移到 DW（减轻 ENTH 负载）

---

## 十一、问题汇总与修复建议

### P0 (紧急) - 需立即处理

| # | 问题 | 影响 | 修复建议 |
|---|------|------|----------|
| 1 | DW hermes-gateway 重启循环 | 微信消息无法发送，cron 不执行 | 检查 PID 冲突，执行 `systemctl stop hermes-gateway && hermes gateway stop && systemctl restart hermes-gateway` |
| 2 | ENTH 内存严重不足 (swap 97%) | 服务可能 OOM 崩溃 | 扩容内存至 4GB 或迁移 mailcow |
| 3 | DW MySQL 无备份 | 数据丢失风险 | 配置宝塔自动备份，每日全量 + binlog |

### P1 (重要) - 一周内处理

| # | 问题 | 影响 | 修复建议 |
|---|------|------|----------|
| 4 | ENTH Hermes Gateway 未运行 | cron 任务不执行 | `hermes gateway install --system && systemctl start hermes-gateway` |
| 5 | API Key 失效 (BB 复核/CLUES 晚报) | 任务持续失败 | 更新 `.env` 或配置中心的 API Key |
| 6 | MySQL 监听所有接口 | 安全风险 | 修改 `my.cnf` 绑定 `127.0.0.1` |
| 7 | 无健康检查告警 | 故障无法及时发现 | 配置 webhook 或邮件告警 |
| 8 | 代码无备份 | 代码丢失风险 | 配置 git 仓库 + 坚果云自动备份 |

### P2 (建议) - 一月内处理

| # | 问题 | 影响 | 修复建议 |
|---|------|------|----------|
| 9 | DW 坚果云扫描冗余 | 资源浪费 | 移除 DW 整点扫描 cron |
| 10 | ENTH 开放端口过多 | 攻击面大 | 审查并关闭不必要端口 |
| 11 | 无 MySQL 主从复制 | DW 宕机数据库不可用 | 配置 ENTH 为只读从库 |
| 12 | 微信发送限流 | 日报可能发送失败 | 联系微信或改用企业微信 |
| 13 | 无故障转移机制 | 单点故障 | 设计关键服务 failover 方案 |
| 14 | 无配置管理中心 | 配置分散 | 考虑引入配置中心或统一 .env 管理 |
| 15 | 无日志集中收集 | 问题排查困难 | 配置 ELK 或简易日志聚合 |
| 16 | 无监控仪表盘 | 状态不直观 | 部署 Grafana + Prometheus |

---

## 十二、修复优先级与时间估算

### 第一阶段 (今日)
```bash
# 1. 修复 DW Gateway
systemctl stop hermes-gateway
/root/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main gateway stop
systemctl start hermes-gateway

# 2. 启动 ENTH Gateway
hermes gateway install --system
systemctl start hermes-gateway

# 3. 配置 DW MySQL 备份
# 通过宝塔面板配置每日 3:00 自动备份
```

### 第二阶段 (本周)
1. 更新失效的 API Key
2. 修改 MySQL 绑定地址
3. 配置健康检查告警
4. 配置代码备份

### 第三阶段 (本月)
1. ENTH 内存扩容或 mailcow 迁移
2. 移除 DW 冗余扫描任务
3. 审查并收紧防火墙规则
4. 设计 MySQL 主从方案

---

## 十三、附录

### A. 关键配置文件位置

| 文件 | 位置 |
|------|------|
| DW nginx 配置 | `/www/server/panel/vhost/nginx/*.conf` |
| DW systemd 服务 | `/etc/systemd/system/projectmate.service` |
| ENTH nginx 配置 | `/www/server/panel/vhost/nginx/*.conf` |
| ENTH systemd 服务 | `/etc/systemd/system/{bookbaker,socialseed,clues-dev,console-api}.service` |
| 健康检查脚本 | `/root/.hermes/scripts/health_check.sh` |
| Courier 脚本 | `/root/.hermes/scripts/courier.sh` |
| 坚果云扫描 | `/root/scripts/nutstore_batch_scan.py` (ENTH) |

### B. 关键端口清单

**DW**:
- 80/443: Nginx
- 888: 宝塔面板
- 3306: MySQL
- 8000: ProjectMate
- 8501: WeChat Ingest API
- 28790: Hermes Gateway (本地)

**ENTH**:
- 80/443: Nginx
- 887/888: Nginx (多域名)
- 3306: MySQL
- 3307: MySQL SSH 隧道 (本地)
- 5432: PostgreSQL (本地)
- 8110: BookBaker
- 8111: SocialSeed
- 8001/333: CLUES
- 8502: Console API (本地)
- 25/465/587/993/995: mailcow

### C. 审计命令参考

```bash
# 系统概览
uptime && free -h && df -h

# 进程检查
ps aux --sort=-%mem | head -20

# 端口监听
ss -tlnp

# systemd 服务
systemctl list-units --type=service --state=running

# crontab
crontab -l

# hermes cron
~/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main cron list

# 健康检查
/root/.hermes/scripts/health_check.sh
```

---

**报告生成**: Hermes Agent  
**审计执行时间**: 2026-06-13 20:15 CST
