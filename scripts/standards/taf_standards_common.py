#!/usr/bin/env python3.11
# -*- coding: utf-8 -*-
"""TAF 标准体系导出/恢复 共用逻辑（单一实现，供 export 与 restore 两个脚本 import）

之所以单独成文件：`is_legacy_config` 的判定口径必须两端一致 —— 导出端据此在 manifest 里
标 `legacy_format`，恢复端据此给出「这是重构前归档件」的明确提示，不能各写一套。
"""
import re
import subprocess

# 数据结构契约（见 references/standard-plugin-schema-contract.md）
LONG_KEYS = ('scoring_criteria', 'evaluation_method', 'affected_subjects', 'reference_standard')
LEGACY_KEYS = ('criteria', 'method', 'subjects', 'ref')
ID_RE = re.compile(r'^P\d-\d{2}$')


def is_legacy_config(cfg: dict) -> bool:
    """判断一份 config 是否仍是 2026-09-10 字段规范化之前的历史格式。

    判据（任一命中即视为 legacy）：条目里出现旧短键；或条目 id 不符合 P#-## 编码
    （历史外标件用过 P3-DB01 这类带 DB 外部码的编号）。
    """
    for it in cfg.get('items') or []:
        if any(k in it for k in LEGACY_KEYS):
            return True
        if not ID_RE.match(str(it.get('id', ''))):
            return True
    return False


def legacy_reasons(cfg: dict) -> list[str]:
    """给出 legacy 的具体原因（供提示信息用）"""
    out = []
    sk = sorted({k for it in cfg.get('items') or [] for k in LEGACY_KEYS if k in it})
    if sk:
        out.append('沿用旧短键 ' + '/'.join(sk))
    bad = sorted({str(it.get('id')) for it in cfg.get('items') or []
                  if not ID_RE.match(str(it.get('id', '')))})
    if bad:
        out.append('含历史外标编号 ' + '、'.join(bad[:4]) + ('…' if len(bad) > 4 else ''))
    return out


def psql(db: str, q: str, fetch: bool = True):
    """执行 SQL；fetch=True 返回去空白的文本结果。失败即抛 SystemExit（避免静默半途而废）"""
    r = subprocess.run(['psql', '-d', db, '-U', 'postgres', '-t', '-A', '-c', q],
                       capture_output=True, text=True)
    if r.returncode:
        raise SystemExit('psql 失败:\n' + r.stderr)
    return r.stdout.strip() if fetch else r.stdout


def psql_apply(db: str, sql_text: str):
    """批量写库：走 stdin 传参（config 达 MB 级时命令行参数会 Too long），显式事务 + ON_ERROR_STOP"""
    r = subprocess.run(['psql', '-d', db, '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-f', '-'],
                       input=sql_text, capture_output=True, text=True)
    if r.returncode:
        raise SystemExit('写入失败（事务已回滚）:\n' + r.stderr[-1500:])
    return r.stdout
