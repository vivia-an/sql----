#!/usr/bin/env python3
"""
Constraint generator for Megatron-LM distributed training validation.
Ensures generated constraints match the format and style of predefined_constraints.json
"""

import json
import copy
import re
from typing import Dict, List, Any
from datetime import datetime


class ChineseConstraintGeneratorNoUnicode:
    """Constraint generator ensuring format and style consistency."""

    def __init__(self, constraints_file_path: str):
        self.constraints_file_path = constraints_file_path
        self.constraints_data = {}
        self.chinese_patterns = {}

    def load_and_analyze_patterns(self) -> bool:
        """Load and analyze existing constraint patterns."""
        try:
            with open(self.constraints_file_path, 'r', encoding='utf-8') as f:
                self.constraints_data = json.load(f)

            self.chinese_patterns = self._analyze_chinese_patterns()
            return True
        except Exception as e:
            print(f"Failed to load constraints file: {e}")
            return False

    def _analyze_chinese_patterns(self) -> Dict[str, Any]:
        """Analyze naming and description patterns."""
        patterns = {
            'naming_patterns': {
                'key_suffixes': [],
                'name_patterns': [],
                'description_styles': []
            },
            'technical_terms': {
                'chinese_terms': [],
                'english_terms': [],
                'mixed_terms': []
            },
            'stage_references': [],
            'condition_patterns': []
        }

        constraints = self.constraints_data.get('constraints', {})

        for category_name, category_constraints in constraints.items():
            for constraint_key, constraint in category_constraints.items():
                if constraint_key.endswith('检查'):
                    patterns['naming_patterns']['key_suffixes'].append('检查')

                name = constraint.get('name', '')
                if '检查' in name:
                    patterns['naming_patterns']['name_patterns'].append(name)

                description = constraint.get('description', '')
                chinese_terms = self._extract_chinese_terms(description)
                english_terms = self._extract_english_terms(description)

                patterns['technical_terms']['chinese_terms'].extend(chinese_terms)
                patterns['technical_terms']['english_terms'].extend(english_terms)

                applicable_conditions = constraint.get('applicable_conditions', {})
                if isinstance(applicable_conditions, dict):
                    stage = applicable_conditions.get('stage', '')
                    if stage and isinstance(stage, str):
                        patterns['stage_references'].append(stage)
                elif isinstance(applicable_conditions, list):
                    for condition in applicable_conditions:
                        if isinstance(condition, str) and ('stage' in condition or 'model-after' in condition):
                            patterns['stage_references'].append(condition)

        for key in patterns['technical_terms']:
            patterns['technical_terms'][key] = self._safe_dedupe(patterns['technical_terms'][key])

        patterns['stage_references'] = self._safe_dedupe(patterns['stage_references'])

        return patterns

    def _safe_dedupe(self, items: List[Any]) -> List[Any]:
        """Deduplicate list while preserving order."""
        result = []
        for item in items:
            if item not in result:
                result.append(item)
        return result

    def _extract_chinese_terms(self, text: str) -> List[str]:
        """Extract Chinese technical terms."""
        chinese_terms = []
        terms = ['一致性', '检查', '权重', '梯度', '参数', '优化器', '更新', '阶段',
                '传播', '反向', '前向', '训练', '同步', '通信', '分片', '累积',
                '验证', '监控', '异常', '完整性', '有效性', '分布式']

        for term in terms:
            if term in text:
                chinese_terms.append(term)

        return chinese_terms

    def _extract_english_terms(self, text: str) -> List[str]:
        """Extract preserved English technical terms."""
        english_terms = []
        english_patterns = [
            r'model-after-\w+', r'grad_\w+', r'cksum', r'rank', r'DP', r'TP', r'PP',
            r'shared_experts', r'LayerNorm', r'Router', r'ZeRO', r'requires_grad'
        ]

        for pattern in english_patterns:
            matches = re.findall(pattern, text)
            english_terms.extend(matches)

        return english_terms

    def generate_chinese_constraints(self) -> Dict[str, Dict[str, Any]]:
        """Generate new constraints in Chinese format."""
        new_constraints = {
            'zero_optimization': {},
            'training_progress': {},
            'data_parallel': {},
            'tensor_parallel': {},
            'pipeline_parallel': {},
            'model_integrity': {}
        }

        new_constraints['zero_optimization'] = self._generate_zero_chinese_constraints()
        new_constraints['training_progress'] = self._generate_progress_chinese_constraints()
        new_constraints['data_parallel'] = self._generate_dp_chinese_extensions()
        new_constraints['tensor_parallel'] = self._generate_tp_chinese_extensions()
        new_constraints['pipeline_parallel'] = self._generate_pp_chinese_extensions()
        new_constraints['model_integrity'] = self._generate_integrity_chinese_extensions()

        return new_constraints

    def _generate_zero_chinese_constraints(self) -> Dict[str, Any]:
        """Generate ZeRO optimization constraints."""
        constraints = {}

        constraints["ZeRO参数分片一致性检查"] = {
            "name": "ZeRO优化参数分片在不同rank间一致性检查",
            "description": "在ZeRO优化启用时，检查参数分片在不同rank间的一致性。确保每个rank只持有指定的参数片段，避免参数重复或丢失。",
            "type": "consistency",
            "logic": "",
            "tables": ["coredump"],
            "params": {},
            "applicable_conditions": {
                "zero_stage": ">= 1",
                "stage": "= 'model-after-optimizer-step'"
            }
        }

        constraints["ZeRO梯度累积一致性检查"] = {
            "name": "ZeRO优化梯度累积过程一致性检查",
            "description": "检查ZeRO优化下梯度累积过程中，梯度分片在各rank间的累积一致性。确保梯度正确分片并在AllReduce前保持数据完整性。",
            "type": "consistency",
            "logic": "",
            "tables": ["coredump"],
            "params": {"min_accumulation_steps": 1},
            "applicable_conditions": {
                "zero_stage": ">= 2",
                "stage": "= 'main-grad-in-backward'"
            }
        }

        constraints["ZeRO优化器状态分片检查"] = {
            "name": "ZeRO-2/3模式优化器状态分片检查",
            "description": "在ZeRO-2/3模式下，验证优化器状态(momentum, variance)正确分片存储在对应rank上。检查状态分片的cksum一致性。",
            "type": "partition",
            "logic": "",
            "tables": ["coredump"],
            "params": {},
            "applicable_conditions": {
                "zero_stage": ">= 2",
                "stage": "= 'model-after-optimizer-step'"
            }
        }

        return constraints

    def _generate_progress_chinese_constraints(self) -> Dict[str, Any]:
        """Generate training progress constraints."""
        constraints = {}

        constraints["训练损失递减趋势检查"] = {
            "name": "训练过程损失值递减趋势检查",
            "description": "检查训练过程中损失值的整体递减趋势，识别异常的损失波动或发散。使用滑动窗口分析损失变化率。",
            "type": "validity",
            "logic": "",
            "tables": ["training_metrics"],
            "params": {"window_size": 10, "tolerance": 0.1},
            "applicable_conditions": {
                "step": "> 10"
            }
        }

        constraints["学习率调度执行一致性检查"] = {
            "name": "学习率调度器执行一致性检查",
            "description": "验证学习率调度器的执行是否符合配置的调度策略(线性、余弦、阶梯等)。检查实际学习率与预期值的一致性。",
            "type": "consistency",
            "logic": "",
            "tables": ["training_metrics"],
            "params": {},
            "applicable_conditions": {
                "lr_scheduler": "!= 'none'"
            }
        }

        constraints["梯度范数异常波动检查"] = {
            "name": "训练过程梯度范数异常波动检查",
            "description": "监控梯度范数的变化，检测梯度爆炸、梯度消失等异常情况。当梯度范数超过阈值时标记为异常。",
            "type": "validity",
            "logic": "",
            "tables": ["training_metrics"],
            "params": {"grad_norm_threshold": 10.0},
            "applicable_conditions": {
                "stage": "= 'model-after-backward'"
            }
        }

        return constraints

    def _generate_dp_chinese_extensions(self) -> Dict[str, Any]:
        """Generate data parallel constraint extensions."""
        constraints = {}

        constraints["DP通信完成后参数同步检查"] = {
            "name": "DP AllReduce通信完成后参数同步检查",
            "description": "验证AllReduce通信完成后，所有DP rank的参数是否完全同步。检查通信后各rank参数的cksum一致性。",
            "type": "consistency",
            "logic": "",
            "tables": ["coredump"],
            "params": {},
            "applicable_conditions": {
                "dp": "> 1",
                "stage": "= 'model-after-allreduce'"
            }
        }

        return constraints

    def _generate_tp_chinese_extensions(self) -> Dict[str, Any]:
        """Generate tensor parallel constraint extensions."""
        constraints = {}

        constraints["TP切分边界连续性检查"] = {
            "name": "TP张量切分边界连续性检查",
            "description": "验证张量并行切分的边界索引在各TP rank间是否连续和一致。确保切分后的张量能正确拼接重构。",
            "type": "consistency",
            "logic": "",
            "tables": ["coredump"],
            "params": {},
            "applicable_conditions": {
                "tp": "> 1"
            }
        }

        return constraints

    def _generate_pp_chinese_extensions(self) -> Dict[str, Any]:
        """Generate pipeline parallel constraint extensions."""
        constraints = {}

        constraints["PP激活值传递完整性检查"] = {
            "name": "PP流水线激活值传递完整性检查",
            "description": "验证流水线不同stage间激活值传递的正确性和完整性。检查激活值的shape、数据类型和数值范围。",
            "type": "completeness",
            "logic": "",
            "tables": ["coredump"],
            "params": {},
            "applicable_conditions": {
                "pp": "> 1",
                "stage": "LIKE 'activation-transfer-%'"
            }
        }

        return constraints

    def _generate_integrity_chinese_extensions(self) -> Dict[str, Any]:
        """Generate model integrity constraint extensions."""
        constraints = {}

        constraints["模型权重数值稳定性检查"] = {
            "name": "模型权重数值稳定性检查",
            "description": "检查模型权重是否出现NaN、Inf等数值不稳定问题。监控权重的数值范围和分布是否在正常范围内。",
            "type": "validity",
            "logic": "",
            "tables": ["coredump"],
            "params": {"weight_range_threshold": 100.0},
            "applicable_conditions": {}
        }

        return constraints

    def merge_with_existing_constraints(self, new_constraints: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
        """Merge new constraints with existing ones."""
        merged_data = copy.deepcopy(self.constraints_data)
        original_count = self._count_constraints(merged_data)

        for category, constraints in new_constraints.items():
            if category not in merged_data['constraints']:
                merged_data['constraints'][category] = {}

            for constraint_key, constraint in constraints.items():
                if constraint_key not in merged_data['constraints'][category]:
                    merged_data['constraints'][category][constraint_key] = constraint
                    print(f"Added constraint: {category}::{constraint_key}")
                else:
                    print(f"Constraint exists, skipped: {category}::{constraint_key}")

        merged_data['metadata']['last_updated'] = datetime.now().strftime("%Y-%m-%d")
        merged_data['metadata']['version'] = "1.2"

        if 'partition' not in merged_data['metadata']['constraint_types']:
            merged_data['metadata']['constraint_types']['partition'] = "分区约束，检查数据分片的正确性"
        if 'completeness' not in merged_data['metadata']['constraint_types']:
            merged_data['metadata']['constraint_types']['completeness'] = "完整性约束，检查数据的完整性"

        new_count = self._count_constraints(merged_data)
        print(f"\nConstraint merge completed:")
        print(f"  Original count: {original_count}")
        print(f"  New count: {new_count}")
        print(f"  Added: {new_count - original_count}")

        return merged_data

    def _count_constraints(self, data: Dict[str, Any]) -> int:
        """Count total constraints."""
        total = 0
        constraints = data.get('constraints', {})
        for category in constraints.values():
            total += len(category)
        return total

    def save_constraints_to_json(self, merged_data: Dict[str, Any]) -> bool:
        """Save constraints to JSON file."""
        try:
            backup_path = f"{self.constraints_file_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            with open(self.constraints_file_path, 'r', encoding='utf-8') as f:
                backup_content = f.read()
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(backup_content)
            print(f"Backup created at: {backup_path}")

            with open(self.constraints_file_path, 'w', encoding='utf-8') as f:
                json.dump(merged_data, f, ensure_ascii=False, indent=2)

            print(f"Constraints successfully written to JSON file")
            return True

        except Exception as e:
            print(f"Failed to save constraints to JSON: {e}")
            return False

    def verify_json_integrity(self) -> bool:
        """Verify JSON file integrity after write."""
        try:
            with open(self.constraints_file_path, 'r', encoding='utf-8') as f:
                reloaded_data = json.load(f)

            required_keys = ['constraints', 'metadata']
            for key in required_keys:
                if key not in reloaded_data:
                    print(f"Missing required field: {key}")
                    return False

            constraints = reloaded_data.get('constraints', {})
            expected_categories = ['data_parallel', 'tensor_parallel', 'pipeline_parallel',
                                 'zero_optimization', 'model_integrity', 'training_progress']

            for category in expected_categories:
                if category not in constraints:
                    print(f"Missing constraint category: {category}")
                    return False

            chinese_constraints_found = 0
            for category, cat_constraints in constraints.items():
                for constraint_key, constraint in cat_constraints.items():
                    if self._is_chinese_constraint(constraint_key, constraint):
                        chinese_constraints_found += 1

            total_constraints = sum(len(cat) for cat in constraints.values())

            print(f"JSON integrity verification passed")
            print(f"  Total constraints: {total_constraints}")
            print(f"  Chinese constraints: {chinese_constraints_found}")
            return True

        except Exception as e:
            print(f"JSON integrity verification failed: {e}")
            return False

    def _is_chinese_constraint(self, key: str, constraint: Dict[str, Any]) -> bool:
        """Check if constraint uses Chinese."""
        chinese_chars = re.findall(r'[\u4e00-\u9fff]', key)
        name = constraint.get('name', '')
        chinese_in_name = re.findall(r'[\u4e00-\u9fff]', name)
        return len(chinese_chars) > 0 or len(chinese_in_name) > 0

    def _get_file_size(self) -> float:
        """Get file size in KB."""
        import os
        try:
            size_bytes = os.path.getsize(self.constraints_file_path)
            return round(size_bytes / 1024, 2)
        except:
            return 0.0

    def run_complete_generation_and_save(self) -> bool:
        """Run complete constraint generation and save workflow."""
        print("Starting constraint generation and save workflow...")

        if not self.load_and_analyze_patterns():
            print("Pattern analysis failed")
            return False

        print("\nGenerating constraints...")
        new_constraints = self.generate_chinese_constraints()

        total_new = sum(len(constraints) for constraints in new_constraints.values())
        print(f"Successfully generated {total_new} constraints")

        print("\nMerging with existing constraints...")
        merged_data = self.merge_with_existing_constraints(new_constraints)

        print("\nWriting to JSON file...")
        if not self.save_constraints_to_json(merged_data):
            print("Write failed")
            return False

        print("\nVerifying JSON integrity...")
        if not self.verify_json_integrity():
            print("Integrity verification failed")
            return False

        print("\nConstraint generation and save workflow completed")
        return True


def main():
    """Main execution function."""
    constraints_file = "sdccheck/config/predefined_constraints.json"

    generator = ChineseConstraintGeneratorNoUnicode(constraints_file)
    success = generator.run_complete_generation_and_save()

    if success:
        print("\nAll tasks completed. Constraints successfully written to JSON file.")
    else:
        print("\nWorkflow execution failed")


if __name__ == "__main__":
    main()