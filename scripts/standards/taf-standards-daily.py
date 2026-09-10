#!/usr/bin/env python3.11
# -*- coding: utf-8 -*-
"""TAF 标准体系 —— 每日自动化作业（导出 → 按需入库 → 冷备 → 坚果云）

背景：8 套体系的「规则设定与权重」原只在运行库，属单点。本作业每日执行：
  1. 导出比对：`taf-standards-export.py --check` 判定内容是否变化
  2. 有变化才入库：重跑导出 → `git add standards` → commit → push（**不产生空提交**）
  3. 冷备：`pg_dump` 单表（standard_plugins）+ 全库 → gzip 到本地备份目录，保留 30 天
  4. 异地：scp 到 ENTH → `rclone copy` 到坚果云 `07_DEV/TAF/备份/`（云端同样保留 30 天）
  5. 输出逐项状态（cron 以 no-agent 模式投递），并追加日志；任一关键步骤失败则以非零码退出

设计约束：
  · 幂等：内容无变化时不写文件、不提交、不空转（冷备仍每日做，属快照而非版本）
  · 关键失败可见：导出失败 / 冷备失败 / 推送失败 → exit 1
  · 不改数据：全程只读运行库
"""
import datetime
import pathlib
import shutil
import subprocess
import sys

REPO = pathlib.Path('/root/TAF')
CANON = REPO / 'scripts' / 'standards'
EXPORT = CANON / 'taf-standards-export.py'
GEN = CANON / 'taf_standards_common.py'          # 共享模块（psql 等）
LOCAL_BACKUP = pathlib.Path('/data/disk1/backups/taf')
RETENTION_DAYS = 30
NUTSTORE_DIR = 'nutstore:07_DEV/TAF/备份/'
ENTH = 'enth'
LOG = pathlib.Path.home() / '.hermes' / 'logs' / 'taf-standards-daily.log'
DB = 'taf'

sys.path.insert(0, str(CANON))
from taf_standards_common import psql  # noqa: E402


def sh(*a, timeout=600, **kw):
    return subprocess.run(a, capture_output=True, text=True, timeout=timeout, **kw)


def ssh_enth(cmd: str, timeout=600):
    return sh('ssh', ENTH, cmd, timeout=timeout)


def log(lines: list[str], out: list[str]):
    out.extend(lines)
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open('a', encoding='utf-8') as fh:
        for l in lines:
            fh.write(l + '\n')


def main() -> int:
    ts = datetime.datetime.now()
    stamp = ts.strftime('%Y%m%d_%H%M')
    day = ts.strftime('%Y%m%d')
    out, failed = [], []
    log([f"═══ {ts.strftime('%Y-%m-%d %H:%M:%S')} TAF 标准体系每日作业 ═══"], out)

    # ── 1) 导出比对 ──
    ck = sh('python3.11', str(EXPORT), '--check', timeout=300)
    if ck.returncode != 0:
        log(["✗ 导出比对失败", ck.stderr.strip()[:200]], out)
        failed.append('导出比对')
        changed = None
    else:
        changed = 'CONTENT_CHANGED=1' in ck.stdout
        log([f"· 导出比对：{'有变化' if changed else '无变化'}"], out)

    # ── 2) 有变化才入库 ──
    if changed:
        ex = sh('python3.11', str(EXPORT), timeout=300)
        if ex.returncode != 0:
            log(["✗ 导出失败", ex.stderr.strip()[:200]], out)
            failed.append('导出')
        else:
            sh('git', '-C', str(REPO), 'add', 'standards', timeout=120)
            diff = sh('git', '-C', str(REPO), 'diff', '--cached', '--quiet', timeout=120)
            if diff.returncode == 0:
                log(["· 内容有变化但暂存区无差异（可能仅时间戳），跳过提交"], out)
            else:
                cm = sh('git', '-C', str(REPO), 'commit', '-m',
                        f'chore(standards): 自动同步标准体系导出件 {stamp}', timeout=180)
                if cm.returncode != 0:
                    log(["✗ 提交失败", cm.stderr.strip()[:200]], out)
                    failed.append('提交')
                else:
                    sha = sh('git', '-C', str(REPO), 'rev-parse', '--short', 'HEAD').stdout.strip()
                    ph = sh('git', '-C', str(REPO), 'push', 'origin', 'main', timeout=300)
                    if ph.returncode != 0:
                        log([f"✓ 已提交 {sha}（本地）", "✗ 推送失败", ph.stderr.strip()[:200]], out)
                        failed.append('推送')
                    else:
                        log([f"✓ 已提交并推送 {sha}"], out)
    elif changed is False:
        log(["· 无变化 ⇒ 不提交（避免空提交）"], out)

    # ── 3) 冷备（单表 + 全库）──
    LOCAL_BACKUP.mkdir(parents=True, exist_ok=True)
    dumps = []
    for name, args in (('standard_plugins', ['-t', 'standard_plugins']), ('full', [])):
        dst = LOCAL_BACKUP / f'taf_{name}_{day}.sql.gz'
        r = sh('bash', '-o', 'pipefail', '-c',
               f"pg_dump -d {DB} -U postgres {' '.join(args)} --no-owner | gzip > {dst}",
               timeout=900)
        if r.returncode != 0 or not dst.exists() or dst.stat().st_size == 0:
            log([f"✗ 冷备失败（{name}）", (r.stderr or '').strip()[:200]], out)
            failed.append(f'冷备-{name}')
        else:
            dumps.append(dst)
            log([f"✓ 冷备 {name}: {dst.name} {dst.stat().st_size/1024:.1f} KB"], out)

    # ── 4) 本地保留 30 天 ──
    cutoff = ts.timestamp() - RETENTION_DAYS * 86400
    old = [p for p in LOCAL_BACKUP.glob('taf_*.sql.gz') if p.stat().st_mtime < cutoff]
    for p in old:
        p.unlink()
    if old:
        log([f"· 本地清理 {len(old)} 个超期快照（>{RETENTION_DAYS} 天）"], out)

    # ── 5) 异地：ENTH → 坚果云 ──
    if dumps:
        remote_tmp = f'/tmp/taf-backup-{stamp}'
        if ssh_enth(f'mkdir -p {remote_tmp}').returncode != 0:
            log(["✗ 无法连接 ENTH（异地备份未做）"], out)
            failed.append('ENTH 连接')
        else:
            ok_scp = True
            for d in dumps:
                s = sh('scp', str(d), f'{ENTH}:{remote_tmp}/', timeout=900)
                if s.returncode != 0:
                    ok_scp = False
                    log([f"✗ scp 失败 {d.name}", s.stderr.strip()[:150]], out)
            if ok_scp:
                cp = ssh_enth(f'rclone copy {remote_tmp}/ {NUTSTORE_DIR}', timeout=1200)
                if cp.returncode != 0:
                    log(["✗ 坚果云同步失败", cp.stderr.strip()[:200]], out)
                    failed.append('坚果云同步')
                else:
                    lsf = ssh_enth(f'rclone lsf {NUTSTORE_DIR} 2>/dev/null | sort | tail -4')
                    log([f"✓ 已同步坚果云 {NUTSTORE_DIR}",
                         "· 云端最近文件：" + ' | '.join(lsf.stdout.split())], out)
                    ssh_enth(f'rclone delete --min-age {RETENTION_DAYS}d {NUTSTORE_DIR}')
            ssh_enth(f'rm -rf {remote_tmp}')

    status = '✓ 全部成功' if not failed else '✗ 失败项: ' + '、'.join(failed)
    log([f"── {status}", ""], out)
    print('\n'.join(out))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
