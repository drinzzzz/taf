# TAF 标准体系导出件（`standards/`）

本目录是 **TAF 8 套空间类型评估体系（HT 酒店 / MC 商场 / OF 办公 / AP 公寓 / HO 自住 / PK 公园 / RE 租房 / OS 街区）**
的「规则设定与权重」的权威镜像，由脚本从运行库导出。

> ⚠️ **只读目录，请勿手改。** 任何修改都会被下一次导出覆盖。
> 要改条目、文案、权重、测量口径：改运行库（或前端标准编辑页），然后重跑导出脚本。

## 文件说明

| 文件 | 内容 |
|---|---|
| `<code>.json` | 每份标准的完整定义：`code / name / version / status / release_date / config`（config 含 `items`、`weight_presets`、`categories`、`level_config`、`version_notes` 等） |
| `_manifest.json` | 清单：每份文件 md5 + 项数 / 必选数 / Σ权重 / 单位项权重区间 / 测量口径条数 / `legacy_format` 标记 |
| `标准体系总览.md` | 人读成果册：索引 + 每份的维度权重表 + 逐条（三档文案 / 受影响主体 / 评估方法 / 测量口径 / 外标） |

`_manifest.json` 字段语义：`content_updated_at` = **最近一次「标准定义内容」变更时间**
（判定口径 = 各份标准的 canonical md5 集合是否变化）；manifest 自身的派生字段（统计、`legacy_format` 标记等）
变化不推动该时间。`legacy_format: true` 的是重构前的历史归档件（沿用旧短键或含 `P3-DB01` 这类历史外标编号），
仅供追溯，恢复器会拒绝直接回灌（需先做字段规范化迁移）。

## 工具与所在位置（单一事实源）

| 工具 | 规范位置（唯一实现，入库） | 调用入口 |
|---|---|---|
| 导出器 | `scripts/standards/taf-standards-export.py` | `~/.hermes/scripts/taf-standards-export.py`（软链） |
| 恢复器 | `scripts/standards/taf-standards-restore.py` | `~/.hermes/scripts/taf-standards-restore.py`（软链） |
| 共用判定 | `scripts/standards/taf_standards_common.py` | 同上（被两个脚本 import） |
| 每日作业 | `scripts/standards/taf-standards-daily.py` | `~/.hermes/scripts/taf-standards-daily.py`（**薄启动器**，非软链 —— cron 校验器拒绝指向目录外的软链） |

## 生成与校验

```bash
python3.11 ~/.hermes/scripts/taf-standards-export.py            # 导出（写文件）
python3.11 ~/.hermes/scripts/taf-standards-export.py --check    # 只比对：CONTENT_CHANGED=0|1
```

- 变更判定只比对「每份标准的 canonical md5」，与运行时间无关；且**只写有差异的文件** ⇒
  内容不变时整个目录零 diff、零空提交（运行日志写在 `~/.hermes/logs/taf-standards-export.log`，不入库）。
- 输出目录可用环境变量 `TAF_STANDARDS_OUT` 覆盖（默认本目录；供隔离测试用）。

## 自动化与备份

- **每日 03:30**：Hermes cron「TAF-标准体系每日导出与冷备」（no-agent，脚本
  `taf-standards-daily.py`）→ 有变化才 `git add standards` + commit + push；随后做冷备。
- **三级留存**：
  | 层 | 位置 | 保留 |
  |---|---|---|
  | 版本历史 | 本仓库 `standards/`（git） | 永久（每次内容变更一个提交） |
  | 本地快照 | `/data/disk1/backups/taf/taf_{standard_plugins,full}_YYYYMMDD.sql.gz` | 30 天 |
  | 异地冷备 | 坚果云 `07_DEV/TAF/备份/`（经 ENTH 的 rclone） | 30 天 |
- 每日作业日志：`~/.hermes/logs/taf-standards-daily.log`。

## 恢复

```bash
python3.11 ~/.hermes/scripts/taf-standards-restore.py --file standards/tafs_ht_v1.0.json --dry-run
python3.11 ~/.hermes/scripts/taf-standards-restore.py --file standards/tafs_ht_v1.0.json --apply
```

恢复器默认**只校验不写**，`--apply` 才落库；写前自动留存快照（`/root/TAF/backups/standards-restore/`）。
校验项：文件 md5 与清单一致、条目结构（3 档 5/3/0 + 长键齐）、Σ权重=1.0、单位项权重 ≤4%、
计数自洽、引擎仿真（全确认 100 分 5★）、历史格式拒收、`tafs_os_v1.1`（兴顺里绑定件）默认拒写（需 `--allow-os`）。
