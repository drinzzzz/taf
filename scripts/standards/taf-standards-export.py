#!/usr/bin/env python3.11
# -*- coding: utf-8 -*-
"""TAF 8 套体系「规则设定与权重」权威导出器

用途：把运行库 PG `taf.standard_plugins` 的全部标准（含 archived）导出成可版本化、
可阅读、可恢复的资料：
  <out-dir>/<code>.json          每份标准的完整定义（code/name/version/status/release_date/config）
  <out-dir>/_manifest.json       清单：每份文件 md5 + 项数/必选/Σ权重/单位项权重区间/测量口径条数
  <out-dir>/标准体系总览.md       人读成果册：8 套 × 维度权重 × 逐条（三档文案/主体/评估方法/测量口径/外标）
  <out-dir>/README.md            目录说明（schema、恢复方式、生成规则）

设计要点：
  · 单一事实源 = 运行库；本目录是导出的镜像，**永远不要手改**（会被下次导出覆盖）
  · 文件用 sort_keys 序列化 ⇒ 内容不变时字节不变 ⇒ git 无空提交
  · 变更判定只看「每份标准的 canonical md5」，与生成时间无关
  · 只读库，不写库（恢复是另一个脚本 taf-standards-restore.py 的事）

用法：
  taf-standards-export.py                  # 导出（写文件）
  taf-standards-export.py --check          # 只比对不写，输出 CONTENT_CHANGED=0|1
  taf-standards-export.py --out-dir DIR    # 指定输出目录（默认 /root/TAF/standards）
  taf-standards-export.py --quiet
"""
import argparse
import datetime
import hashlib
import json
import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from taf_standards_common import is_legacy_config, legacy_reasons, psql  # noqa: E402

# 输出目录可用环境变量覆盖（供隔离测试/多环境使用），默认即生产目录
DEFAULT_OUT = pathlib.Path(os.environ.get('TAF_STANDARDS_OUT', '/root/TAF/standards'))
DB = 'taf'
SCHEMA_VERSION = 1
GENERATOR = 'taf-standards-export.py v1'
def dumps(obj) -> str:
    """规范化序列化：内容不变 ⇒ 字节不变（保证 git 无空提交）"""
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, indent=2, separators=(',', ': '))


def q(sql: str) -> str:
    """绑定本模块的库名"""
    return psql(DB, sql)


def load_standards() -> list[dict]:
    """读取全部标准（含 archived），按 status(active 在前) + code 排序"""
    raw = q("select json_agg(x order by (x->>'status') <> 'active', x->>'code') from ("
               "select json_build_object("
               "'code', code, 'name', name, 'version', version, 'status', status, "
               "'release_date', to_char(release_date, 'YYYY-MM-DD'), 'config', config"
               ") as x from standard_plugins) t")
    return json.loads(raw) if raw and raw != 'null' else []


def dim_stats(cfg: dict):
    """维度 → (项数, 权重, 单位项权重%)"""
    pl = list(cfg.get('weight_presets') or {})
    w = (cfg.get('weight_presets') or {}).get(pl[0], {}) if pl else {}
    n = {}
    for i in cfg.get('items', []):
        n[i['category']] = n.get(i['category'], 0) + 1
    rows = []
    for d in sorted(n):
        ww = w.get(d)
        rows.append({'dim': d, 'items': n[d], 'weight': ww,
                     'per_item_pct': round(ww / n[d] * 100, 2) if ww is not None else None})
    return rows, pl[0] if pl else None, w


def file_bytes(obj) -> bytes:
    return (dumps(obj) + '\n').encode('utf-8')


def md5(b: bytes) -> str:
    return hashlib.md5(b).hexdigest()


def render_overview(rows: list[dict], content_updated_at: str) -> str:
    L = ['# TAF 标准体系总览（规则设定与权重）', '',
         f'> 生成方式：`{GENERATOR}` ｜ 数据源：PG `{DB}.standard_plugins` ｜ 内容更新时间：{content_updated_at}',
         '> **本文件由脚本生成，勿手改**；改条目/权重请在运行库或前端改，再重跑导出。', '',
         '## 索引', '',
         '| 代码 | 名称 | 版本 | 状态 | 项数 | 必选 | Σ权重 | 单位项权重区间 | 测量口径 |',
         '|---|---|---|---|---|---|---|---|---|']
    for r in rows:
        s = r['stats']
        rng = '—' if s['per_item_min'] is None else f"{s['per_item_min']:.2f}% ~ {s['per_item_max']:.2f}%"
        flag = ' ⚠️历史格式' if s.get('legacy_format') else ''
        L.append(f"| `{r['code']}` | {r['name']} | {r['version']} | {r['status']}{flag} | "
                 f"{s['items']} | {s['prerequisite_count']} | {s['sum_weight']:.2f} | {rng} | "
                 f"{s['measure_spec_count']} |")
    L.append('')
    for idx, r in enumerate(rows, 1):
        cfg = r['config']
        s = r['stats']
        L += [f"## {idx}. {r['name']}（`{r['code']}`）", '',
              f"- 版本 {r['version']} ｜ 状态 **{r['status']}** ｜ 发布 {r['release_date']}"
              f" ｜ 项数 {s['items']}（必选 {s['prerequisite_count']}）"
              f" ｜ Σ权重 {s['sum_weight']:.2f} ｜ 测量口径 {s['measure_spec_count']} 条", '']
        if s.get('legacy_format'):
            L += [f"- ⚠️ **历史格式（重构前归档件）**：{'；'.join(legacy_reasons(cfg))}"
                  f" —— 仅供追溯，回灌前需先做字段规范化迁移。", '']
        if cfg.get('regulation_refs'):
            L += [f"- 顶层引用标准：{'、'.join(cfg['regulation_refs'])}", '']
        L += ['### 维度权重', '', '| 维度 | 名称 | 项数 | 权重 | 单位项权重 |', '|---|---|---|---|---|']
        names = {c['id']: c.get('name', '') for c in cfg.get('categories', [])}
        for d in r['dims']:
            pi = '—' if d['per_item_pct'] is None else f"{d['per_item_pct']:.2f}%"
            L.append(f"| {d['dim']} | {names.get(d['dim'], '')} | {d['items']} | "
                     f"{d['weight']:.2f} | {pi} |")
        L += ['', '### 逐条清单', '']
        cur = None
        for it in cfg.get('items', []):
            if it['category'] != cur:
                cur = it['category']
                L += [f"#### {cur} {names.get(cur, '')}", '']
            crit = sorted(it.get('scoring_criteria', []), key=lambda x: -x['score'])
            L.append(f"**{it['id']} {it['name']}** ｜ {'必选' if it.get('type') == 'prerequisite' else '可选'}"
                     f" ｜ 满分 {it.get('score_max')}"
                     + (f" ｜ 无此设施不计分" if it.get('is_optional_facility') else ''))
            for c in crit:
                L.append(f"- {c['score']} 分：{c['label']}")
            L.append(f"- 受影响主体：{'、'.join(it.get('affected_subjects') or []) or '—'}")
            L.append(f"- 评估方法：{it.get('evaluation_method') or '—'}")
            m = it.get('measure_spec')
            if m:
                L.append(f"- 测量口径：{m.get('metric')}｜目标 {m.get('target')}"
                         f"{(' ' + m['unit']) if m.get('unit') else ''}｜方法 {m.get('method')}"
                         f"｜容差 {m.get('tolerance')}｜证据 {m.get('evidence')}")
            refs = it.get('external_refs') or []
            if refs:
                L.append(f"- 外标条款：{'；'.join(refs)}")
            if it.get('reference_standard'):
                L.append(f"- 参考标准：{it['reference_standard']}")
            L.append('')
    return '\n'.join(L).rstrip() + '\n'


README = """# TAF 标准体系导出件（`standards/`）

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
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out-dir', default=str(DEFAULT_OUT))
    ap.add_argument('--check', action='store_true', help='只比对不写；输出 CONTENT_CHANGED=0|1')
    ap.add_argument('--quiet', action='store_true')
    a = ap.parse_args()
    out = pathlib.Path(a.out_dir)

    standards = load_standards()
    if not standards:
        raise SystemExit('库内没有标准记录')

    # 组装每份的内容与摘要
    rows, files, hashes = [], {}, {}
    for st in standards:
        code = st['code']
        payload = {k: st[k] for k in ('code', 'name', 'version', 'status', 'release_date', 'config')}
        b = file_bytes(payload)
        files[code] = b
        hashes[code] = md5(b)
        dims, pl, w = dim_stats(st['config'])
        per = [d['per_item_pct'] for d in dims if d['per_item_pct'] is not None]
        rows.append({
            **{k: st[k] for k in ('code', 'name', 'version', 'status', 'release_date')},
            'config': st['config'], 'dims': dims,
            'stats': {
                'items': len(st['config'].get('items', [])),
                'prerequisite_count': sum(1 for i in st['config'].get('items', [])
                                          if i.get('type') == 'prerequisite'),
                'product_line': pl,
                'weight_presets': w,
                'sum_weight': round(sum(w.values()), 6) if w else 0.0,
                'per_item_min': min(per) if per else None,
                'per_item_max': max(per) if per else None,
                'measure_spec_count': sum(1 for i in st['config'].get('items', [])
                                          if i.get('measure_spec')),
                'legacy_format': is_legacy_config(st['config']),
            }})

    # 变更判定（与生成时间无关）
    man_path = out / '_manifest.json'
    old = json.loads(man_path.read_text(encoding='utf-8')) if man_path.exists() else {}
    old_hashes = (old.get('standards') or {})
    old_map = {k: v.get('md5') for k, v in old_hashes.items()}
    changed = (old_map != hashes) or any(not (out / f'{c}.json').exists() for c in hashes)

    if a.check:
        print(f"CONTENT_CHANGED={1 if changed else 0}")
        if not a.quiet and changed:
            for c in hashes:
                if old_map.get(c) != hashes[c]:
                    print(f"  · {c} 变更")
        return 0

    out.mkdir(parents=True, exist_ok=True)
    now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    # 内容无变化时沿用上次的「内容更新时间」⇒ manifest 与总览字节稳定（git 不产生空提交）
    content_at = now if changed else (old.get('content_updated_at') or now)
    manifest = {
        'schema_version': SCHEMA_VERSION,
        'generator': GENERATOR,
        'source': f'postgresql://{DB}/standard_plugins',
        'content_changed_this_run': bool(changed),
        'content_updated_at': content_at,
        'standards': {r['code']: {
            'file': f"{r['code']}.json", 'md5': hashes[r['code']],
            'name': r['name'], 'version': r['version'], 'status': r['status'],
            **r['stats']} for r in rows},
    }
    # 只写有差异的文件（内容相同则连 mtime 都不动）
    written = []
    for code, b in files.items():
        f = out / f'{code}.json'
        if not f.exists() or f.read_bytes() != b:
            f.write_bytes(b)
            written.append(f.name)
    for name, text in (('_manifest.json', dumps(manifest) + '\n'),
                       ('标准体系总览.md', render_overview(rows, content_at)),
                       ('README.md', README)):
        f = out / name
        b = text.encode('utf-8')
        if not f.exists() or f.read_bytes() != b:
            f.write_bytes(b)
            written.append(name)
    # 运行日志写在仓库外（避免污染 git 工作区）
    log = pathlib.Path.home() / '.hermes' / 'logs' / 'taf-standards-export.log'
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open('a', encoding='utf-8') as fh:
        fh.write(f"{now} CONTENT_CHANGED={1 if changed else 0} "
                 f"written={len(written)} standards={len(files)}\n")

    if not a.quiet:
        print(f"导出目录: {out}")
        print(f"CONTENT_CHANGED={1 if changed else 0}  文件 {len(files)} 份 + manifest + 总览 + README"
              f"（本次落盘 {len(written)} 个）")
        for r in rows:
            s = r['stats']
            rng = '—' if s['per_item_min'] is None else f"{s['per_item_min']:.2f}%~{s['per_item_max']:.2f}%"
            print(f"  {r['code']:16} {r['status']:8} 项{s['items']:>3} 必选{s['prerequisite_count']:>3} "
                  f"Σw={s['sum_weight']:.2f} 单位项 {rng} 口径{s['measure_spec_count']:>3} "
                  f"md5={hashes[r['code']][:8]}{'  ⚠️历史格式' if s.get('legacy_format') else ''}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
