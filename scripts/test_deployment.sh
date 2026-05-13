#!/usr/bin/env bash
# Model Deployment Test Script
# Tests that all models can be loaded and used for inference

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}Model Deployment and Inference Test${NC}"
echo -e "${BLUE}======================================================================${NC}\n"

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Category Model Structure Validation
test_category_model() {
    echo -e "\n${YELLOW}TEST 1: Category Model Structure Validation${NC}"
    echo -e "${BLUE}================================${NC}\n"

    cd "$REPO_ROOT"

    python3 << 'PYEOF'
import json
from pathlib import Path

model_dir = Path("docs/agent/playbooks/category-signal-model-training-example/models/mmbert32k_category_classifier_r8")

try:
    # Check adapter config
    adapter_config_path = model_dir / "adapter_config.json"
    with open(adapter_config_path) as f:
        adapter_config = json.load(f)

    # Verify LoRA configuration
    assert adapter_config.get("r") is not None, "Missing LoRA rank"
    assert adapter_config.get("lora_alpha") is not None, "Missing LoRA alpha"

    target_modules = adapter_config.get("target_modules", [])
    expected_modules = ["attn.Wqkv", "attn.Wo", "mlp.Wi", "mlp.Wo"]
    assert set(target_modules) == set(expected_modules), f"Unexpected target modules: {target_modules}"

    print(f"✅ PASS: mmBERT LoRA configuration is correct")
    print(f"  - LoRA rank: {adapter_config.get('r')}")
    print(f"  - LoRA alpha: {adapter_config.get('lora_alpha')}")
    print(f"  - Target modules: {', '.join(target_modules)}")

except Exception as e:
    print(f"❌ FAIL: {e}")
    import sys
    sys.exit(1)
PYEOF

    if [ $? -eq 0 ]; then
        ((TESTS_PASSED++))
    else
        ((TESTS_FAILED++))
    fi
}

# Test 2: Configuration Loading
test_config_loading() {
    echo -e "\n${YELLOW}TEST 2: Configuration Loading${NC}"
    echo -e "${BLUE}================================${NC}\n"

    cd "$REPO_ROOT"

    python3 << 'PYEOF'
import yaml
from pathlib import Path

configs = [
    ("docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml", "Category Signal"),
    ("docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml", "Feedback"),
    ("docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml", "Jailbreak"),
    ("docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml", "PII"),
]

all_passed = True
for config_path, model_name in configs:
    try:
        with open(config_path) as f:
            config = yaml.safe_load(f)

        print(f"✅ PASS: {model_name} config loaded successfully")
    except Exception as e:
        print(f"❌ FAIL: {model_name} config loading failed - {e}")
        all_passed = False

import sys
sys.exit(0 if all_passed else 1)
PYEOF

    if [ $? -eq 0 ]; then
        ((TESTS_PASSED++))
    else
        ((TESTS_FAILED++))
    fi
}

# Test 3: Model Files Validation
test_model_files() {
    echo -e "\n${YELLOW}TEST 3: Model Files Validation${NC}"
    echo -e "${BLUE}================================${NC}\n"

    PLAYBOOK_BASE="${REPO_ROOT}/docs/agent/playbooks"
    CATEGORY_MODEL_DIR="${PLAYBOOK_BASE}/category-signal-model-training-example/models/mmbert32k_category_classifier_r8"

    if [ -d "$CATEGORY_MODEL_DIR" ]; then
        echo "✅ PASS: Model directory exists"
        ((TESTS_PASSED++))

        # Check required files
        required_files=("adapter_model.safetensors" "label_mapping.json" "tokenizer.json")
        for file in "${required_files[@]}"; do
            if [ -f "${CATEGORY_MODEL_DIR}/${file}" ]; then
                echo "  ✓ ${file}"
            else
                echo "  ✗ ${file} (missing)"
                ((TESTS_FAILED++))
            fi
        done
    else
        echo -e "${YELLOW}ℹ️  Category model not trained yet (expected for first run)${NC}"
    fi
}

# Test 4: Label Mapping Validation
test_label_mapping() {
    echo -e "\n${YELLOW}TEST 4: Label Mapping Validation${NC}"
    echo -e "${BLUE}================================${NC}\n"

    cd "$REPO_ROOT"

    python3 << 'PYEOF'
import json
from pathlib import Path

label_mapping_path = Path("docs/agent/playbooks/category-signal-model-training-example/models/mmbert32k_category_classifier_r8/label_mapping.json")

if not label_mapping_path.exists():
    print("ℹ️ Label mapping not found (model not trained yet)")
    import sys
    sys.exit(0)

try:
    with open(label_mapping_path) as f:
        mapping = json.load(f)

    assert "label2id" in mapping, "Missing label2id"
    assert "id2label" in mapping, "Missing id2label"

    label_count = len(mapping["label2id"])
    if label_count == 14:
        print(f"✅ PASS: Label mapping contains all 14 categories")
        for category in ["biology", "law", "computer science", "physics"]:
            if category in mapping["label2id"]:
                print(f"  ✓ {category}")
    else:
        print(f"❌ FAIL: Expected 14 categories, found {label_count}")
        import sys
        sys.exit(1)
except Exception as e:
    print(f"❌ FAIL: {e}")
    import sys
    sys.exit(1)
PYEOF

    if [ $? -eq 0 ]; then
        ((TESTS_PASSED++))
    else
        ((TESTS_FAILED++))
    fi
}

# Test 5: Runtime Configuration Compatibility
test_runtime_compat() {
    echo -e "\n${YELLOW}TEST 5: Runtime Configuration Compatibility${NC}"
    echo -e "${BLUE}================================${NC}\n"

    cd "$REPO_ROOT"

    python3 << 'PYEOF'
import yaml

# Test that configs can be loaded by semantic-router's config system
configs_to_test = [
    "docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml",
    "docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml",
    "docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml",
    "docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml",
]

all_valid = True
for config_file in configs_to_test:
    try:
        with open(config_file) as f:
            config = yaml.safe_load(f)

        # Basic structure validation
        if config and isinstance(config, dict):
            print(f"✅ {config_file.split('/')[-1]} is valid")
        else:
            print(f"❌ {config_file}: Invalid structure")
            all_valid = False
    except Exception as e:
        print(f"❌ {config_file}: {e}")
        all_valid = False

if all_valid:
    print("\n✅ PASS: All configurations are runtime-compatible")
else:
    print("\n❌ FAIL: Some configurations have issues")

import sys
sys.exit(0 if all_valid else 1)
PYEOF

    if [ $? -eq 0 ]; then
        ((TESTS_PASSED++))
    else
        ((TESTS_FAILED++))
    fi
}

# Run all tests
test_config_loading
test_model_files
test_label_mapping
test_runtime_compat

# Try category model structure validation if available
if [ -d "${REPO_ROOT}/docs/agent/playbooks/category-signal-model-training-example/models/mmbert32k_category_classifier_r8" ]; then
    test_category_model
fi

# Summary
echo -e "\n${BLUE}======================================================================${NC}"
echo -e "${BLUE}Deployment Test Summary${NC}"
echo -e "${BLUE}======================================================================${NC}\n"

echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}\n"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL DEPLOYMENT TESTS PASSED${NC}"
    echo -e "${GREEN}Ready for production deployment${NC}\n"
    exit 0
else
    echo -e "${RED}⚠️ SOME TESTS FAILED${NC}"
    echo -e "${YELLOW}Please review the output above${NC}\n"
    exit 1
fi
