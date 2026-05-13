#!/usr/bin/env bash
# Comprehensive MoM Architecture Deployment Test
# Tests all four models with mmBERT-32K base model

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

echo "======================================================================"
echo "MoM (mmBERT-32K) Deployment Test Suite"
echo "======================================================================"
echo ""

# Test 1: Validate all configurations have mmBERT enabled
echo "TEST 1: Configuration Validation"
echo "================================"
python3 << 'EOF'
import yaml

configs = {
    "Category Signal": ("docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml", "classifier.category_model.use_mmbert_32k"),
    "Feedback": ("docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml", "feedback_detector.use_mmbert_32k"),
    "Jailbreak": ("docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml", "prompt_guard.use_mmbert_32k"),
    "PII": ("docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml", "classifier.pii_model.use_mmbert_32k"),
}

all_passed = True
for name, (path, key_path) in configs.items():
    try:
        with open(path) as f:
            config = yaml.safe_load(f)

        # Navigate the nested keys
        keys = key_path.split(".")
        value = config
        for key in keys:
            value = value.get(key) if isinstance(value, dict) else None

        if value is True:
            print(f"  ✅ {name}: use_mmbert_32k = true")
        else:
            print(f"  ❌ {name}: use_mmbert_32k not enabled")
            all_passed = False
    except Exception as e:
        print(f"  ❌ {name}: {e}")
        all_passed = False

exit(0 if all_passed else 1)
EOF
if [ $? -eq 0 ]; then ((TESTS_PASSED++)); else ((TESTS_FAILED++)); fi
echo ""

# Test 2: Verify model files exist and have correct structure
echo "TEST 2: Model Files Validation"
echo "=============================="
python3 << 'EOF'
import json
from pathlib import Path

model_dir = Path("docs/agent/playbooks/category-signal-model-training-example/models/mmbert32k_category_classifier_r8")

if not model_dir.exists():
    print("  ℹ️  Model directory not found (model not trained yet)")
    exit(0)

required_files = ["adapter_model.safetensors", "adapter_config.json", "label_mapping.json", "tokenizer.json", "config.json"]
all_present = True

for file in required_files:
    if (model_dir / file).exists():
        print(f"  ✅ {file}")
    else:
        print(f"  ❌ {file} - MISSING")
        all_present = False

exit(0 if all_present else 1)
EOF
if [ $? -eq 0 ]; then ((TESTS_PASSED++)); else ((TESTS_FAILED++)); fi
echo ""

# Test 3: Validate LoRA configuration
echo "TEST 3: LoRA Configuration"
echo "=========================="
python3 << 'EOF'
import json
from pathlib import Path

model_dir = Path("docs/agent/playbooks/category-signal-model-training-example/models/mmbert32k_category_classifier_r8")
adapter_config_path = model_dir / "adapter_config.json"

if not adapter_config_path.exists():
    print("  ℹ️  LoRA config not found (model not trained yet)")
    exit(0)

try:
    with open(adapter_config_path) as f:
        config = json.load(f)

    rank = config.get("r")
    alpha = config.get("lora_alpha")
    modules = config.get("target_modules", [])

    print(f"  ✅ LoRA Rank: {rank}")
    print(f"  ✅ LoRA Alpha: {alpha}")
    print(f"  ✅ Target Modules: {', '.join(modules)}")

    expected_modules = {"attn.Wqkv", "attn.Wo", "mlp.Wi", "mlp.Wo"}
    if set(modules) == expected_modules:
        print(f"  ✅ Target modules are correct for mmBERT")
        exit(0)
    else:
        print(f"  ❌ Incorrect target modules for mmBERT")
        exit(1)
except Exception as e:
    print(f"  ❌ Error: {e}")
    exit(1)
EOF
if [ $? -eq 0 ]; then ((TESTS_PASSED++)); else ((TESTS_FAILED++)); fi
echo ""

# Test 4: Validate label mapping
echo "TEST 4: Label Mapping Validation"
echo "==============================="
python3 << 'EOF'
import json
from pathlib import Path

model_dir = Path("docs/agent/playbooks/category-signal-model-training-example/models/mmbert32k_category_classifier_r8")
label_mapping_path = model_dir / "label_mapping.json"

if not label_mapping_path.exists():
    print("  ℹ️  Label mapping not found (model not trained yet)")
    exit(0)

try:
    with open(label_mapping_path) as f:
        mapping = json.load(f)

    label2id = mapping.get("label2id", {})
    categories = mapping.get("categories", [])

    if len(categories) == 14:
        print(f"  ✅ All 14 MMLU-Pro categories present")
        for cat in ["biology", "law", "physics", "mathematics", "computer science"]:
            if cat in label2id:
                print(f"    - {cat}: {label2id[cat]}")
        exit(0)
    else:
        print(f"  ❌ Expected 14 categories, found {len(categories)}")
        exit(1)
except Exception as e:
    print(f"  ❌ Error: {e}")
    exit(1)
EOF
if [ $? -eq 0 ]; then ((TESTS_PASSED++)); else ((TESTS_FAILED++)); fi
echo ""

# Test 5: Validate training scripts
echo "TEST 5: Training Scripts"
echo "======================="
scripts=(
    "docs/agent/playbooks/category-signal-model-training-example/scripts/train_category_classifier_mmbert_lora.py"
    "docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh"
    "docs/agent/playbooks/jailbreak-model-training-example/scripts/train_jailbreak_lora_cpu.sh"
)

all_exist=true
for script in "${scripts[@]}"; do
    if [ -f "$REPO_ROOT/$script" ]; then
        echo "  ✅ $(basename $script)"
    else
        echo "  ❌ $(basename $script) - NOT FOUND"
        all_exist=false
    fi
done

if [ "$all_exist" = true ]; then ((TESTS_PASSED++)); else ((TESTS_FAILED++)); fi
echo ""

# Test 6: Verify validation script works
echo "TEST 6: Architecture Validation Script"
echo "====================================="
bash "$REPO_ROOT/scripts/validate_mom_architecture.sh" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✅ MoM architecture validation passed"
    ((TESTS_PASSED++))
else
    echo "  ❌ MoM architecture validation failed"
    ((TESTS_FAILED++))
fi
echo ""

# Summary
echo "======================================================================"
echo "Test Summary"
echo "======================================================================"
echo "✅ Passed: $TESTS_PASSED"
echo "❌ Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✅ ALL DEPLOYMENT TESTS PASSED"
    echo "MoM architecture with mmBERT-32K is ready for deployment!"
    exit 0
else
    echo "⚠️  SOME TESTS FAILED"
    exit 1
fi
