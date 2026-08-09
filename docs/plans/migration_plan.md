# DW 磁盘迁移工作计划
## 2026-08-04 · 将 /root/.hermes/hermes-agent/ (4.5G) 迁移至 vdc

### 当前状态
- vda1 `/`: 27G/40G (66%) ← 迁移后预计 22G/40G (55%)
- vdc `/data/disk1`: 16G/40G (42%) ← 迁移后预计 20.5G/40G (51%)
- vdb `/data/disk`: 4.8G/20G (26%) ← 不动

### 迁移对象
1. 🎯 主目标: `/root/.hermes/hermes-agent/` (4.5G) → `/data/disk1/hermes/hermes-agent/`
   - venv/ (1.3G)
   - node_modules/ (1.1G)
   - 其他源码和资源 (~2.1G)
2. 🟡 可选: `/root/.vscode-server/` (819M) → 用户重连 VSCode 时自动下载

### 执行流程
1. Hermes 写入迁移脚本到 `/tmp/migrate_hermes.sh`
2. 用 `at now + 1 minute` 调度执行（独立于 Hermes 进程）
3. at 脚本执行:
   a. systemctl stop hermes-gateway
   b. pkill -f "hermes" 确保无残留
   c. rsync 迁移 hermes-agent/ 到 vdc
   d. 创建 symlink
   e. systemctl start hermes-gateway
   f. 写入完成标记

### 恢复方式
- 迁移完成后，用户在 VSCode 中重新连接 ACP 即可继续对话
- systemd 自动拉起 hermes-gateway
- 所有 symlink 路径对 Hermes 透明

### 回滚方案
如需回滚：
```bash
systemctl stop hermes-gateway
rm /root/.hermes/hermes-agent  # 删除 symlink
mv /data/disk1/hermes/hermes-agent /root/.hermes/hermes-agent  # 移回
systemctl start hermes-gateway
```
