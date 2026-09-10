#!/usr/bin/env python3.11
# -*- coding: utf-8 -*-
"""TAF 标准体系 —— 恢复器（从导出件回灌标准定义）

配套 `taf-standards-export.py`。默认**只校验不写**，必须显式 `--apply` 才落库。

安全设计（逐条都是「拒绝」而不是「警告」）：
  1. 文件必须存在、可解析、含 code/name/version/status/config
  2. `--code`（若给）必须与文件内 code 一致
  3. 若同目录 `_manifest.json` 存在且含该 code：文件 md5 必须与清单一致（不符需 `--force`）
  4. 结构校验：items 非空；每条项含长键 id/name/type/category/score_max/scoring_criteria/
     affected_subjects/evaluation_method；档位为 3 档且分值恰为 {5,3,0}；category 必须存在于 categories
  5. 权重校验：weight_presets 单一产品线且 Σ权重 = 1.0（±1e-6）；categories[].weight 与之一致
  6. 计数校验：total_items / prerequisite_count 与 items 实际相符
  7. 引擎仿真：全 confirmed = 100.0 分 / 5★；已选未确认均 > 0；空设施 = 0 分不崩
  8. 硬保护：默认**拒绝对 tafs_os_v1.1（兴顺里绑定件）写入**，需显式 `--allow-os`
  9. 写前自动快照到 `--snapshot-dir`；写入走单事务（BEGIN/COMMIT，ON_ERROR_STOP），写后回读断言

用法：
  taf-standards-restore.py --file standards/tafs_ht_v1.0.json                 # 只校验（默认）
  taf-standards-restore.py --file standards/tafs_ht_v1.0.json --apply       # 真写
  taf-standards-restore.py --code tafs_ht_v1.0 --file X.json --db taf_smoke --apply
退出码：0 成功｜2 校验失败｜3 被保护规则拒绝
"""
import argparse
import datetime
import hashlib
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from taf_standards_common import is_legacy_config, legacy_reasons, psql, psql_apply  # noqa: E402

DEFAULT_DB = 'taf'
DEFAULT_SNAP = pathlib.Path('/root/TAF/backups/standards-restore')
REQ_KEYS = ('id', 'name', 'type', 'category', 'score_max',
            'scoring_criteria', 'affected_subjects', 'evaluation_method')
OS_CODE = 'tafs_os_v1.1'


class Fail(Exception):
    pass


def validate(doc: dict, path: pathlib.Path, manifest: dict | None, force: bool) -> list[str]:
    notes = []
    for k in ('code', 'name', 'version', 'status', 'config'):
        if k not in doc:
            raise Fail(f'文件缺字段 {k}')
    cfg = doc['config']
    code = doc['code']

    if manifest and code in (manifest.get('standards') or {}):
        want = manifest['standards'][code]['md5']
        got = hashlib.md5(path.read_bytes()).hexdigest()
        if want != got:
            if not force:
                raise Fail(f'文件 md5 与 manifest 清单不符（want {want[:8]}… got {got[:8]}…）；'
                           f'确认无误可加 --force')
            notes.append(f'md5 与清单不符但已 --force 放行（清单 {want[:8]}… 实际 {got[:8]}…）')
    else:
        notes.append('未找到该 code 的 manifest 记录，跳过 md5 比对')

    if is_legacy_config(cfg):
        raise Fail('这是重构前的历史归档件（' + '；'.join(legacy_reasons(cfg)) +
                   '），与当前字段契约不一致 ⇒ 拒绝回灌；如需启用请先做字段规范化迁移'
                   '（见 references/standard-plugin-schema-contract.md）')

    items = cfg.get('items') or []
    if not items:
        raise Fail('config.items 为空')
    cats = {c['id'] for c in cfg.get('categories') or []}
    if not cats:
        raise Fail('config.categories 为空')
    bad = []
    for it in items:
        for k in REQ_KEYS:
            if k not in it:
                bad.append(f"{it.get('id')} 缺 {k}")
        sc = sorted((c.get('score') for c in it.get('scoring_criteria') or []), reverse=True)
        if sc != [5, 3, 0]:
            bad.append(f"{it.get('id')} 档位={sc}")
        if it.get('category') not in cats:
            bad.append(f"{it.get('id')} category={it.get('category')} 不在 categories")
        if not (it.get('affected_subjects') or []):
            bad.append(f"{it.get('id')} 受影响主体为空")
    if bad:
        raise Fail('条目结构校验失败：' + '；'.join(bad[:6]) + (f' 等 {len(bad)} 处' if len(bad) > 6 else ''))
    notes.append(f'{len(items)} 条项结构合规（3 档 5/3/0、长键齐、category 合法）')

    pls = list(cfg.get('weight_presets') or {})
    if len(pls) != 1:
        raise Fail(f'weight_presets 应为单一产品线，实为 {pls}')
    if any((it.get('category') or '') not in (cfg['weight_presets'][pls[0]] or {}) for it in items):
        raise Fail('存在 items.category 未在 weight_presets 中定义权重的维度')
    n = {}
    for it in items:
        n[it['category']] = n.get(it['category'], 0) + 1
    w = cfg['weight_presets'][pls[0]]
    if abs(sum(w.values()) - 1.0) > 1e-6:
        raise Fail(f'Σ权重 ≠ 1.0（实际 {sum(w.values()):.8f}）⇒ 满分将不等于 100，拒绝写入')
    over = [d for d in n if w[d] / n[d] > 0.04 + 1e-9]
    if over:
        raise Fail(f'单位项权重越界 >4.00%：' +
                   ', '.join(f'{d} {w[d]/n[d]*100:.2f}%' for d in over))
    catw = {c['id']: c.get('weight') for c in cfg['categories']}
    if any(abs((catw.get(d) or 0) - v) > 1e-9 for d, v in w.items()):
        raise Fail('categories[].weight 与 weight_presets 不一致')
    notes.append(f'权重合规：Σ=1.0，单位项权重 {min(w[d]/n[d] for d in n)*100:.2f}%'
                 f'~{max(w[d]/n[d] for d in n)*100:.2f}%，categories 同步')

    pre = sum(1 for it in items if it.get('type') == 'prerequisite')
    if cfg.get('total_items') != len(items) or cfg.get('prerequisite_count') != pre:
        raise Fail(f'计数不一致：total_items={cfg.get("total_items")}/{len(items)}，'
                   f'prerequisite_count={cfg.get("prerequisite_count")}/{pre}')
    notes.append(f'计数合规：total_items={len(items)}，必选={pre}')

    sys.path.insert(0, '/root/TAF/backend')
    from services.evaluation import EvaluationEngine
    eng = EvaluationEngine(cfg)
    full = eng.calculate_score([{'standard_item_id': i['id'], 'status': 'confirmed', 'quantity': 1}
                                for i in items], product_line=pls[0])
    if abs(full['total_score'] - 100.0) > 0.06 or full['stars'] != 5:
        raise Fail(f'引擎仿真异常：全确认 = {full["total_score"]} 分 / {full["stars"]}★（应 100 分 5★）')
    sel = eng.calculate_score([{'standard_item_id': i['id'], 'status': 'selected', 'quantity': 1}
                               for i in items], product_line=pls[0])
    zero = [d['item_id'] for cs in sel['category_scores'] for d in cs['items'] if d['score'] == 0]
    if zero:
        raise Fail(f'引擎仿真异常：已选未确认出现 0 分项 {zero[:4]}')
    if eng.calculate_score([], product_line=pls[0])['total_score'] != 0.0:
        raise Fail('引擎仿真异常：空设施应得 0 分')
    notes.append('引擎仿真通过：全确认 100 分 5★、已选未确认均 >0、空设施 0 分')
    return notes


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--file', required=True, help='导出件 JSON 路径')
    ap.add_argument('--code', help='目标标准代码（缺省取文件内 code）')
    ap.add_argument('--db', default=DEFAULT_DB)
    ap.add_argument('--apply', action='store_true', help='真正写入（缺省只校验）')
    ap.add_argument('--allow-os', action='store_true', help=f'允许覆盖 {OS_CODE}（兴顺里绑定件）')
    ap.add_argument('--force', action='store_true', help='允许 md5 与 manifest 不符')
    ap.add_argument('--snapshot-dir', default=str(DEFAULT_SNAP))
    ap.add_argument('--quiet', action='store_true')
    a = ap.parse_args()
    say = (lambda *x: None) if a.quiet else print

    path = pathlib.Path(a.file)
    if not path.exists():
        raise SystemExit(f'文件不存在：{path}')
    doc = json.loads(path.read_text(encoding='utf-8'))
    code = a.code or doc.get('code')
    if a.code and doc.get('code') != a.code:
        raise SystemExit(f'--code {a.code} 与文件内 code {doc.get("code")} 不一致')
    if code == OS_CODE and not a.allow_os:
        if a.apply:
            print(f'拒绝：{OS_CODE} 是人宠友好街区（兴顺里）的绑定标准件；'
                  f'确需覆盖请显式加 --allow-os', file=sys.stderr)
            return 3
        print(f'注意：{OS_CODE} 是兴顺里绑定件 —— 本次仅校验（未加 --apply）；'
              f'真要写入需显式加 --allow-os')

    man_path = path.parent / '_manifest.json'
    manifest = json.loads(man_path.read_text(encoding='utf-8')) if man_path.exists() else None

    say(f"目标库: {a.db} ｜ 标准: {code} ｜ 文件: {path}")
    try:
        for n in validate(doc, path, manifest, a.force):
            say(f"  ✓ {n}")
    except Fail as e:
        print(f'校验失败，未写入：{e}', file=sys.stderr)
        return 2

    cur_rows = psql(a.db, f"select count(*) from standard_plugins where code='{code}'")
    if cur_rows != '1':
        print(f'校验失败：目标库 {a.db} 中 code={code} 的记录数为 {cur_rows}（应恰为 1）', file=sys.stderr)
        return 2
    cur = json.loads(psql(a.db, f"select config::text from standard_plugins where code='{code}'"))
    same = cur == doc['config']
    say(f"  ✓ 目标记录存在；与待写入内容{'一致（无需变更）' if same else '不同'}")

    if not a.apply:
        say('未加 --apply ⇒ 只校验不写入。')
        return 0

    snap_dir = pathlib.Path(a.snapshot_dir)
    snap_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    snap = snap_dir / f'{code}-{ts}.json'
    snap.write_text(json.dumps(cur, ensure_ascii=False, sort_keys=True, indent=2) + '\n',
                    encoding='utf-8')
    say(f"  ✓ 写前快照：{snap}")

    payload = json.dumps(doc['config'], ensure_ascii=False).replace("'", "''")
    psql_apply(a.db, f"BEGIN;\nUPDATE standard_plugins SET config='{payload}'::jsonb, "
                     f"updated_at=now() WHERE code='{code}';\nCOMMIT;\n")
    back = json.loads(psql(a.db, f"select config::text from standard_plugins where code='{code}'"))
    if back != doc['config']:
        print('写入后回读与目标不一致（请用写前快照恢复）', file=sys.stderr)
        return 2
    say(f"  ✓ 写入完成并回读一致（项数 {len(back['items'])}）")
    return 0


if __name__ == '__main__':
    sys.exit(main())
