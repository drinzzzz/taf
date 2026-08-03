"""
它界 TAF — 评估引擎
"""
from typing import List, Dict, Optional, Any


class EvaluationEngine:
    """核心评估引擎：依据标准配置计算评分"""

    # ── 评分常量 ──
    MID_SCORE_FACTOR = 0.5       # selected 状态取中档分 = score_max × 50%
    WARNING_THRESHOLD = 50.0     # 板块得分率低于此值触发建议

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.categories = {c["id"]: c for c in config.get("categories", [])}
        self.items = {i["id"]: i for i in config.get("items", [])}
        self.level_config = config.get("level_config", {})
        self.weight_presets = config.get("weight_presets", {})

    def _score_from_status(self, item: Dict, status: str) -> float:
        """将设施状态映射为实际得分，使用 scoring_criteria 分级。
        
        scoring_criteria 格式: [{"score": 5, ...}, {"score": 3, ...}, {"score": 0, ...}]
        已按高分到低分排列。
        """
        criteria = item.get("scoring_criteria", [])
        score_max = item.get("score_max", 5)

        if status == "draft":
            return 0.0
        elif status == "selected":
            # 选中但未确认：取最低非零分或中档分
            if len(criteria) >= 2:
                return float(criteria[-2].get("score", score_max * self.MID_SCORE_FACTOR))
            return score_max * self.MID_SCORE_FACTOR
        elif status in ("confirmed", "installed"):
            # 已确认/已安装：取最高分
            if criteria:
                return float(criteria[0].get("score", score_max))
            return float(score_max)
        return 0.0

    def _best_facility(self, facilities: List[Dict], item_id: str) -> Optional[Dict]:
        """同一标准项可能有多个设施，取状态最优的那个"""
        matches = [f for f in facilities if f.get("standard_item_id") == item_id]
        if not matches:
            return None
        # 优先级: installed > confirmed > selected > draft
        priority = {"installed": 3, "confirmed": 2, "selected": 1, "draft": 0}
        return max(matches, key=lambda f: priority.get(f.get("status", "draft"), 0))

    def calculate_score(
        self,
        facilities: List[Dict],
        product_line: str = "OS",
        custom_weights: Optional[Dict[str, float]] = None,
    ) -> Dict[str, Any]:
        """
        输入：设施列表、产品线、自定义权重
        返回：各板块得分、总分、等级、达标清单
        """
        weights = custom_weights or self.weight_presets.get(product_line, {})

        category_scores = []
        prerequisite_total = 0
        prerequisite_passed = 0

        for cat_id, cat_info in self.categories.items():
            cat_items = [i for i in self.config["items"] if i["category"] == cat_id]
            actual_score = 0.0
            applicable_count = 0
            max_possible = 0.0
            item_details = []

            for item in cat_items:
                fac = self._best_facility(facilities, item["id"])

                # 可选设施且未配置 → 跳过，不计入总分
                if not fac and item.get("is_optional_facility"):
                    item_details.append({
                        "item_id": item["id"],
                        "name": item["name"],
                        "type": item.get("type", "credit"),
                        "score_max": item.get("score_max", 5),
                        "score": -1,
                        "has_facility": False,
                        "status": "n/a",
                        "quantity": 0,
                        "achieved_label": "无此设施（不计分）",
                        "optional_skipped": True,
                    })
                    continue

                applicable_count += 1
                max_possible += item.get("score_max", 5)
                status = fac.get("status", "draft") if fac else "draft"
                qty = fac.get("quantity", 1) if fac else 0

                item_score = self._score_from_status(item, status) if fac else 0.0

                # 必选项追踪
                if item.get("type") == "prerequisite":
                    prerequisite_total += 1
                    if fac and fac.get("status") in ("confirmed", "installed"):
                        prerequisite_passed += 1

                # Find which criteria label was achieved
                criteria = item.get("scoring_criteria", [])
                achieved_label = ""
                if fac and status != "draft":
                    for c in criteria:
                        if item_score >= c.get("score", 0):
                            achieved_label = c.get("label", "")
                            break

                item_details.append({
                    "item_id": item["id"],
                    "name": item["name"],
                    "type": item.get("type", "credit"),
                    "score_max": item.get("score_max", 5),
                    "score": item_score,
                    "has_facility": fac is not None,
                    "status": status,
                    "quantity": qty,
                    "achieved_label": achieved_label,
                })
                actual_score += item_score

            max_score = max_possible

            weight = weights.get(cat_id, cat_info.get("weight", 0))
            percentage = (actual_score / max_score * 100) if max_score > 0 else 0

            category_scores.append({
                "category_id": cat_id,
                "category_name": cat_info["name"],
                "weight": weight,
                "score": round(actual_score, 1),
                "max_score": max_score,
                "percentage": round(percentage, 1),
                "items": item_details,
            })

        # 加权总分（百分制）
        total_score = sum(
            cs["percentage"] * cs["weight"]
            for cs in category_scores
        )

        # 映射等级
        level_info = self._map_level(total_score)

        # 建议
        recommendations = self._generate_recommendations(
            category_scores, prerequisite_passed, prerequisite_total
        )

        return {
            "total_score": round(total_score, 1),
            "level": level_info["label"],
            "stars": level_info["stars"],
            "prerequisite_pass": prerequisite_passed >= prerequisite_total,
            "prerequisite_total": prerequisite_total,
            "prerequisite_passed": prerequisite_passed,
            "category_scores": category_scores,
            "recommendations": recommendations,
        }

    def _map_level(self, score: float) -> Dict:
        levels = self.level_config.get("levels", [])
        for level in sorted(levels, key=lambda x: x["min_score"], reverse=True):
            if score >= level["min_score"]:
                return level
        return levels[-1] if levels else {"stars": 0, "label": "未评级", "min_score": 0}

    def _generate_recommendations(
        self, category_scores: List[Dict], passed: int, total: int
    ) -> List[str]:
        recs = []

        if passed < total:
            recs.append(f"⚠️ 必选项达标 {passed}/{total}，需优先补齐未达标项")

        for cs in category_scores:
            if cs["percentage"] < self.WARNING_THRESHOLD:
                recs.append(f"📌 {cs['category_name']} 得分率仅 {cs['percentage']}%，建议重点改进")

        if not recs:
            recs.append("✅ 各项指标表现良好")

        return recs

    def compare_standards(self, old_config: Optional[Dict], new_code: str) -> Dict:
        """对比新旧标准差异：基于旧标准配置对比新标准"""
        old_items = set()
        old_prereqs = set()
        if old_config:
            old_items = {i["id"] for i in old_config.get("items", [])}
            old_prereqs = {i["id"] for i in old_config.get("items", []) if i.get("type") == "prerequisite"}

        new_items = set(self.items.keys())
        new_prereqs = {i["id"] for i in self.config["items"] if i.get("type") == "prerequisite"}

        added = sorted(new_items - old_items)
        removed = sorted(old_items - new_items) if old_config else []
        prereq_added = sorted(new_prereqs - old_prereqs) if old_config else sorted(new_prereqs)
        prereq_removed = sorted(old_prereqs - new_prereqs) if old_config else []

        return {
            "new_code": new_code,
            "added_items": [{"id": iid, "name": self.items[iid]["name"]} for iid in added],
            "removed_items": [{"id": iid} for iid in removed],
            "new_prerequisites": [{"id": iid, "name": self.items[iid]["name"]} for iid in prereq_added],
            "removed_prerequisites": [{"id": iid} for iid in prereq_removed],
            "total_items_new": len(new_items),
            "total_items_old": len(old_items) if old_config else None,
        }
