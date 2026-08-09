#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SUNRISE 系统 NAS 帧读取优化模块
优化策略：
1. 帧索引缓存 (避免重复扫描)
2. 尾部扫描 (快速获取最近帧)
3. 分块读取 (内存友好)
4. 文件列表缓存 (避免重复 glob)

用法:
    from optimized_storage_reader import get_reader
    reader = get_reader()
    frame, pic_path, frame_time = reader.get_latest_frame()
"""

import os
import logging
import pickle
import struct
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Tuple
from pathlib import Path

logger = logging.getLogger(__name__)

# 配置
FRAME_INDEX_CACHE = '/tmp/sunrise_frame_index.pkl'
PIC_LIST_CACHE_TTL = 60  # 文件列表缓存 TTL (秒)
TAIL_READ_SIZE = 15 * 1024 * 1024  # 尾部读取大小 (15MB)
FRAME_SIZE_ESTIMATE = 1200000  # 单帧大小估计 (1.2MB)
READ_CHUNK_SIZE = 524288  # 扫描时分块大小 (512KB)


class FrameIndexCache:
    """帧索引缓存管理器"""
    
    def __init__(self, cache_path: str = FRAME_INDEX_CACHE):
        self.cache_path = cache_path
        self.index: Dict[str, List[int]] = self._load()
    
    def _load(self) -> Dict[str, List[int]]:
        if os.path.exists(self.cache_path):
            try:
                with open(self.cache_path, 'rb') as f:
                    data = pickle.load(f)
                    logger.info(f"已加载帧索引缓存：{len(data)} 个文件")
                    return data
            except Exception as e:
                logger.warning(f"加载缓存失败：{e}")
        return {}
    
    def save(self):
        try:
            with open(self.cache_path, 'wb') as f:
                pickle.dump(self.index, f)
            logger.debug(f"已保存帧索引缓存：{len(self.index)} 个文件")
        except Exception as e:
            logger.warning(f"保存缓存失败：{e}")
    
    def get(self, pic_path: str) -> Optional[List[int]]:
        key = self._make_key(pic_path)
        return self.index.get(key)
    
    def set(self, pic_path: str, offsets: List[int]):
        key = self._make_key(pic_path)
        self.index[key] = offsets
        self.save()
    
    def _make_key(self, pic_path: str) -> str:
        """生成缓存键 (包含文件大小以检测变更)"""
        try:
            size = os.path.getsize(pic_path)
            return f"{pic_path}:{size}"
        except:
            return pic_path
    
    def cleanup_stale(self, existing_files: List[str]):
        """清理不存在的文件缓存"""
        existing_keys = {self._make_key(f) for f in existing_files if os.path.exists(f)}
        stale_keys = [k for k in self.index.keys() if k not in existing_keys]
        for k in stale_keys:
            del self.index[k]
        if stale_keys:
            self.save()
            logger.info(f"已清理 {len(stale_keys)} 个过期缓存条目")


class OptimizedStorageReader:
    """优化的存储读取器"""
    
    def __init__(self, storage_root: str = None):
        self.storage_root = storage_root or '/mnt/nas/SUNRISE'
        self.frame_cache = FrameIndexCache()
        self._pic_list_cache: Optional[List[str]] = None
        self._pic_list_mtime: float = 0
        self._pic_list_cache_time: float = 0
    
    def _get_datadir(self) -> str:
        return os.path.join(self.storage_root, 'datadir0')
    
    def _get_pic_list(self) -> List[str]:
        """获取 .pic 文件列表 (带缓存)"""
        datadir = self._get_datadir()
        if not os.path.exists(datadir):
            return []
        
        current_mtime = os.path.getmtime(datadir)
        current_time = datetime.now().timestamp()
        
        # 检查缓存是否有效
        if (self._pic_list_cache is not None and 
            current_mtime == self._pic_list_mtime and
            current_time - self._pic_list_cache_time < PIC_LIST_CACHE_TTL):
            return self._pic_list_cache
        
        # 重新扫描
        pics = []
        for f in os.listdir(datadir):
            if f.endswith('.pic'):
                full_path = os.path.join(datadir, f)
                # 只包含有实际内容的文件 (>1MB)
                if os.path.getsize(full_path) > 1000000:
                    pics.append(full_path)
        
        self._pic_list_cache = sorted(pics)
        self._pic_list_mtime = current_mtime
        self._pic_list_cache_time = current_time
        
        # 清理过期缓存
        self.frame_cache.cleanup_stale(self._pic_list_cache)
        
        return self._pic_list_cache
    
    def _scan_frame_offsets(self, pic_path: str) -> List[int]:
        """扫描文件中的帧偏移 (分块读取，内存友好)"""
        # 检查缓存
        cached = self.frame_cache.get(pic_path)
        if cached is not None:
            logger.debug(f"使用缓存的帧索引：{pic_path} ({len(cached)} 帧)")
            return cached
        
        logger.info(f"扫描帧索引：{pic_path}")
        offsets = []
        buffer = b''
        hik_header_seen = False
        
        with open(pic_path, 'rb') as f:
            while True:
                chunk = f.read(READ_CHUNK_SIZE)
                if not chunk:
                    break
                
                buffer += chunk
                file_pos = f.tell() - len(buffer)
                
                # 在 buffer 中找 SOI 标记
                pos = 0
                while True:
                    idx = buffer.find(b'\xff\xd8', pos)
                    if idx == -1:
                        break
                    
                    abs_pos = file_pos + idx
                    
                    # 检查是否是海康帧头后的 JPEG
                    if idx >= 8:
                        magic = buffer[idx-8:idx-4]
                        if magic == b'vuFj':
                            # 这是海康帧头后的帧，跳过 8 字节头
                            offsets.append(abs_pos + 8)
                            hik_header_seen = True
                        elif abs_pos < 16:
                            # 文件开头的帧
                            offsets.append(abs_pos)
                        else:
                            offsets.append(abs_pos)
                    elif abs_pos < 16:
                        offsets.append(abs_pos)
                    else:
                        offsets.append(abs_pos)
                    
                    pos = idx + 2
                
                # 保留最后 16 字节 (可能跨越块边界)
                buffer = buffer[-16:] if len(buffer) > 16 else buffer
        
        logger.info(f"扫描完成：{pic_path} ({len(offsets)} 帧)")
        self.frame_cache.set(pic_path, offsets)
        return offsets
    
    def _estimate_frame_time(self, pic_path: str, frame_idx: int, total_frames: int) -> datetime:
        """估算帧的拍摄时间"""
        try:
            mtime = os.path.getmtime(pic_path)
            # 假设 mtime 是最后一帧的写入时间
            last_frame_time = datetime.fromtimestamp(mtime)
            # 每帧间隔 10 秒
            frame_time = last_frame_time - timedelta(seconds=(total_frames - 1 - frame_idx) * 10)
            return frame_time
        except Exception as e:
            logger.warning(f"估算时间失败：{e}")
            return datetime.now()
    
    def _get_tail_frames(self, pic_path: str, num_frames: int = 5) -> List[Tuple[bytes, int]]:
        """从文件末尾获取最近 N 帧 (返回帧数据和索引)"""
        file_size = os.path.getsize(pic_path)
        
        # 估算需要读取的大小
        read_size = min(num_frames * FRAME_SIZE_ESTIMATE, TAIL_READ_SIZE)
        
        frames = []
        with open(pic_path, 'rb') as f:
            f.seek(max(0, file_size - read_size))
            tail_offset = f.tell()
            tail = f.read()
            
            # 找所有 SOI
            positions = []
            pos = 0
            while True:
                pos = tail.find(b'\xff\xd8', pos)
                if pos == -1:
                    break
                
                abs_pos = tail_offset + pos
                
                # 检查海康帧头
                if pos >= 8 and tail[pos-8:pos-4] == b'vuFj':
                    positions.append((abs_pos + 8, True))  # 跳过 8 字节头
                else:
                    positions.append((abs_pos, False))
                
                pos += 2
            
            # 提取最后 N 帧
            all_offsets = self._scan_frame_offsets(pic_path)
            
            for i, (start_pos, has_header) in enumerate(positions[-num_frames:]):
                f.seek(start_pos)
                
                # 读取帧数据
                frame_data = b''
                while True:
                    chunk = f.read(65536)
                    if not chunk:
                        break
                    frame_data += chunk
                    
                    # 找 EOI
                    eoi_idx = frame_data.find(b'\xff\xd9')
                    if eoi_idx != -1:
                        frame_data = frame_data[:eoi_idx + 2]
                        break
                
                if frame_data:
                    # 计算帧索引
                    frame_idx = len(all_offsets) - len(positions) + i
                    frames.append((frame_data, frame_idx))
        
        return frames
    
    def get_latest_frame(self) -> Tuple[Optional[bytes], Optional[str], Optional[datetime]]:
        """获取最新帧"""
        pics = self._get_pic_list()
        if len(pics) < 2:
            logger.warning("没有可用的 .pic 文件")
            return None, None, None
        
        # 取倒数第二个 (避免正在写入的)
        pic_path = pics[-2]
        logger.debug(f"读取最新帧：{pic_path}")
        
        # 从末尾获取最后一帧
        frames = self._get_tail_frames(pic_path, num_frames=1)
        if not frames:
            logger.error(f"无法从 {pic_path} 读取帧")
            return None, None, None
        
        frame_data, frame_idx = frames[0]
        offsets = self._scan_frame_offsets(pic_path)
        frame_time = self._estimate_frame_time(pic_path, frame_idx, len(offsets))
        
        logger.info(f"获取最新帧：{pic_path} 帧#{frame_idx} 时间={frame_time}")
        return frame_data, pic_path, frame_time
    
    def get_frame_for_time(self, target_time: datetime, tolerance_sec: int = 30) -> Tuple[Optional[bytes], Optional[str], Optional[datetime]]:
        """获取指定时间最近的帧"""
        pics = self._get_pic_list()
        if not pics:
            return None, None, None
        
        best_frame = None
        best_diff = float('inf')
        best_pic = None
        best_time = None
        
        # 只检查最近的文件 (提高效率)
        for pic_path in pics[-10:]:
            offsets = self._scan_frame_offsets(pic_path)
            if not offsets:
                continue
            
            for idx in range(len(offsets)):
                frame_time = self._estimate_frame_time(pic_path, idx, len(offsets))
                diff = abs((frame_time - target_time).total_seconds())
                
                if diff < best_diff:
                    best_diff = diff
                    best_pic = pic_path
                    best_time = frame_time
                    
                    # 读取帧
                    with open(pic_path, 'rb') as f:
                        f.seek(offsets[idx])
                        frame_data = f.read(FRAME_SIZE_ESTIMATE)
                        eoi_idx = frame_data.find(b'\xff\xd9')
                        if eoi_idx != -1:
                            best_frame = frame_data[:eoi_idx + 2]
                        else:
                            best_frame = frame_data
                
                # 找到足够接近的帧，提前返回
                if diff < 5:
                    logger.info(f"找到匹配帧：{pic_path} 帧#{idx} 时间差={diff:.1f}s")
                    return best_frame, best_pic, best_time
        
        if best_frame:
            logger.info(f"找到最近帧：{best_pic} 时间差={best_diff:.1f}s")
        else:
            logger.warning(f"未找到接近 {target_time} 的帧")
        
        return best_frame, best_pic, best_time
    
    def get_recent_frames(self, num_frames: int = 10) -> List[Tuple[bytes, str, datetime]]:
        """获取最近 N 帧"""
        pics = self._get_pic_list()
        if not pics:
            return []
        
        results = []
        # 从最后一个完成的文件获取
        for pic_path in reversed(pics[-5:]):
            frames = self._get_tail_frames(pic_path, num_frames=len(pics) * 2)
            offsets = self._scan_frame_offsets(pic_path)
            
            for frame_data, frame_idx in frames:
                frame_time = self._estimate_frame_time(pic_path, frame_idx, len(offsets))
                results.append((frame_data, pic_path, frame_time))
                
                if len(results) >= num_frames:
                    break
            
            if len(results) >= num_frames:
                break
        
        return results[:num_frames]
    
    def clear_cache(self):
        """清除所有缓存"""
        self._pic_list_cache = None
        self._pic_list_mtime = 0
        self.frame_cache.index = {}
        self.frame_cache.save()
        logger.info("已清除所有缓存")


# 全局实例
_reader: Optional[OptimizedStorageReader] = None


def get_reader(storage_root: str = None) -> OptimizedStorageReader:
    """获取或创建读取器实例"""
    global _reader
    if _reader is None:
        _reader = OptimizedStorageReader(storage_root)
    return _reader


def reset_reader():
    """重置读取器 (用于测试或配置变更)"""
    global _reader
    if _reader:
        _reader.clear_cache()
    _reader = None


# 性能测试
if __name__ == '__main__':
    import time
    
    logging.basicConfig(level=logging.INFO)
    
    reader = get_reader()
    
    print("=" * 60)
    print("SUNRISE NAS 帧读取性能测试")
    print("=" * 60)
    
    # 测试 1: 获取最新帧
    print("\n[测试 1] 获取最新帧")
    start = time.time()
    frame, pic, frame_time = reader.get_latest_frame()
    elapsed = time.time() - start
    print(f"  耗时：{elapsed:.3f}s")
    print(f"  文件：{pic}")
    print(f"  时间：{frame_time}")
    print(f"  帧大小：{len(frame) if frame else 0:,} 字节")
    
    # 测试 2: 再次获取 (应使用缓存)
    print("\n[测试 2] 再次获取最新帧 (缓存)")
    start = time.time()
    frame, pic, frame_time = reader.get_latest_frame()
    elapsed = time.time() - start
    print(f"  耗时：{elapsed:.3f}s")
    
    # 测试 3: 获取最近 10 帧
    print("\n[测试 3] 获取最近 10 帧")
    start = time.time()
    frames = reader.get_recent_frames(10)
    elapsed = time.time() - start
    print(f"  耗时：{elapsed:.3f}s")
    print(f"  获取帧数：{len(frames)}")
    
    # 测试 4: 按时间查询
    print("\n[测试 4] 按时间查询")
    target = datetime.now() - timedelta(minutes=5)
    start = time.time()
    frame, pic, frame_time = reader.get_frame_for_time(target)
    elapsed = time.time() - start
    print(f"  耗时：{elapsed:.3f}s")
    print(f"  目标时间：{target}")
    print(f"  实际时间：{frame_time}")
    if frame_time:
        print(f"  时间差：{abs((frame_time - target).total_seconds()):.1f}s")
    
    print("\n" + "=" * 60)
    print("测试完成")
    print("=" * 60)
