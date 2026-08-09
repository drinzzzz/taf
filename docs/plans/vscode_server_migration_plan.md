# vscode-server 迁移补完计划
## 2026-08-04 · 修复首次迁移遗留的 symlink 缺失问题

### 背景
- 首次迁移脚本（01:13）成功将 hermes-agent 迁至 vdc ✅
- vscode-server 的 bulk 数据（code 二进制 + extensions，822M）已迁入 `/data/disk1/hermes/vscode-server/`
- 但 symlink 未创建，`/root/.vscode-server` 仍为实体目录（120K 运行态文件）

### 当前状态
- 源 `/root/.vscode-server/`：120K，6 文件（cli token、pid、log 等运行态）
- 目标 `/data/disk1/hermes/vscode-server/`：822M，3211 文件（code 二进制 + extensions）
- rsync --delete dry-run 显示会从目标删大量文件 → 不可用 delete 模式

### 执行步骤

1. **rsync 补同步**（no-delete，仅新增/更新运行态文件）
   ```bash
   rsync -av --ignore-existing /root/.vscode-server/ /data/disk1/hermes/vscode-server/
   ```
   风险：极低，只写不删，忽略已存在文件

2. **停 gateway + 备份**
   ```bash
   systemctl stop hermes-gateway
   mv /root/.vscode-server /root/.vscode-server.bak
   ```

3. **建 symlink**
   ```bash
   ln -s /data/disk1/hermes/vscode-server /root/.vscode-server
   ```

4. **起 gateway**
   ```bash
   systemctl start hermes-gateway
   ```

5. **验证**
   - symlink 指向正确
   - gateway 正常运行
   - 磁盘释放确认（/root 下 .vscode-server 不再占实体空间）

### 回滚
```bash
systemctl stop hermes-gateway
rm /root/.vscode-server
mv /root/.vscode-server.bak /root/.vscode-server
systemctl start hermes-gateway
```
