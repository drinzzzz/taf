# TAF 标准体系导出件（`standards/`）

本目录是 **TAF 8 套空间类型评估体系（HT 酒店 / MC 商场 / OF 办公 / AP 公寓 / HO 自住 / PK 公园 / RE 租房 / OS 街区）**
的「规则设定与权重」的权威镜像，由脚本从运行库导出。

> ⚠️ **只读目录，请勿手改。** 任何修改都会被下一次导出覆盖。
> 要改条目、文案、权重、测量口径：改运行库（或前端标准编辑页），然后重跑导出脚本。

## 文件说明

| 文件 | 内容 |
|---|---|
| `<code>.json` | 每份标准的完整定义：`code / name / version / status / release_date / config`（config 含 `items`、`weight_presets`、`categories`、`level_config`、`version_notes` 等） |
| `_manifest.json` | 清单：每份文件 md5 + 项数 / 必选数 / Σ权重 / 单位项权重区间 / 测量口径条数；`content_updated_at` = 最近一次**内容**变更时间 |
| `标准体系总览.md` | 人读成果册：索引 + 每份的维度权重表 + 逐条（三档文案 / 受影响主体 / 评估方法 / 测量口径 / 外标） |

## 生成与校验

```bash
python3.11 ~/.hermes/scripts/taf-standards-export.py            # 导出（写文件）
python3.11 ~/.hermes/scripts/taf-standards-export.py --check    # 只比对：CONTENT_CHANGED=0|1
```

- 变更判定只比对「每份标准的 canonical md5」，与运行时间无关；且**只写有差异的文件** ⇒
  内容不变时整个目录零 diff、零空提交（运行日志写在 `~/.hermes/logs/taf-standards-export.log`，不入库）。
- 文件以 `sort_keys` 规范化序列化 ⇒ 内容不变则字节不变（git diff 干净）。
- manifest 里 `legacy_format: true` 的是**重构前的历史归档件**（沿用旧短键或含 `P3-DB01` 这类历史外标编号），
  仅供追溯；恢复器会拒绝直接回灌这类文件（需先做字段规范化迁移）。

- 每日 03:30 由 Hermes cron 自动执行（有变化才 commit & push），并同步 pg_dump 冷备到坚果云
  `07_DEV/TAF/备份/`。恢复见 `~/.hermes/scripts/taf-standards-restore.py`。

## 恢复

```bash
python3.11 ~/.hermes/scripts/taf-standards-restore.py --code tafs_ht_v1.0 --file standards/tafs_ht_v1.0.json --dry-run
python3.11 ~/.hermes/scripts/taf-standards-restore.py --code tafs_ht_v1.0 --file standards/tafs_ht_v1.0.json --apply
```

恢复器会先校验（md5 / 项数 / 必选数 / Σ权重=1.0 / 引擎仿真全 confirmed = 100 分），写前自动留存快照；
默认**拒绝对 `tafs_os_v1.1`（兴顺里绑定件）写入**，除非显式 `--allow-os`。
