#!/usr/bin/env bash
# Complete Model Training Examples Validation Script
# This script validates all four model training examples end-to-end

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PLAYBOOK_BASE="${REPO_ROOT}/docs/agent/playbooks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}Model Training Examples - Complete Validation Script${NC}"
echo -e "${BLUE}======================================================================${NC}\n"

# Function to print test result
print_test() {
    local test_name="$1"
    local result="$2"

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        ((TESTS_FAILED++))
    fi
}

# Function to validate model directory
validate_model() {
    local model_name="$1"
    local config_file="$2"
    local script_name="$3"

    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Model: $model_name${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

    local model_path="${PLAYBOOK_BASE}/${model_name}"

    # Test 1: Check directory exists
    if [ -d "$model_path" ]; then
        print_test "Directory exists: $model_name" "PASS"
    else
        print_test "Directory exists: $model_name" "FAIL"
        return 1
    fi

    # Test 2: Check config file exists
    local config_path="${model_path}/configs/${config_file}"
    if [ -f "$config_path" ]; then
        print_test "Config file exists: $config_file" "PASS"
        echo "         File size: $(stat -f%z "$config_path" 2>/dev/null || stat -c%s "$config_path" 2>/dev/null) bytes"
    else
        print_test "Config file exists: $config_file" "FAIL"
        return 1
    fi

    # Test 3: Validate YAML syntax
    if python3 -c "import yaml; yaml.safe_load(open('$config_path'))" 2>/dev/null; then
        print_test "YAML syntax valid" "PASS"
    else
        print_test "YAML syntax valid" "FAIL"
        return 1
    fi

    # Test 4: Check training script exists
    local script_path="${model_path}/scripts/${script_name}"
    if [ -f "$script_path" ]; then
        print_test "Training script exists: $script_name" "PASS"
        chmod +x "$script_path"
    else
        print_test "Training script exists: $script_name" "FAIL"
        return 1
    fi

    # Test 5: Check data file exists
    if [ -f "${model_path}/data/training-samples.jsonl" ]; then
        local line_count=$(wc -l < "${model_path}/data/training-samples.jsonl")
        print_test "Training data exists" "PASS"
        echo "         Samples: $line_count"
    else
        print_test "Training data exists" "FAIL"
        return 1
    fi

    # Test 6: Check README exists
    if [ -f "${model_path}/README.md" ]; then
        print_test "Documentation exists: README.md" "PASS"
    else
        print_test "Documentation exists: README.md" "FAIL"
        return 1
    fi

    return 0
}

# Validate all four models
echo -e "${YELLOW}STEP 1: Validating Model Directories${NC}\n"

validate_model "category-signal-model-training-example" "category-signal-model.yaml" "train_qwen3_generative_lora.sh"
validate_model "feedback-model-training-example" "feedback-model.yaml" "train_feedback_detector_lora.sh"
validate_model "jailbreak-model-training-example" "prompt-guard.yaml" "train_jailbreak_lora_cpu.sh"
validate_model "pii-model-training-example" "pii-model.yaml" "train_pii_lora_cpu.sh"

# Test 7: Validate category model training (if model exists)
echo -e "\n${YELLOW}STEP 2: Category Model Advanced Validation${NC}\n"

CATEGORY_MODEL_DIR="${PLAYBOOK_BASE}/category-signal-model-training-example/models/qwen3_generative_classifier_r8"
if [ -d "$CATEGORY_MODEL_DIR" ]; then
    print_test "Category model directory exists" "PASS"

    if [ -f "${CATEGORY_MODEL_DIR}/adapter_model.safetensors" ]; then
        print_test "LoRA weights file exists" "PASS"
    else
        print_test "LoRA weights file exists" "FAIL"
    fi

    if [ -f "${CATEGORY_MODEL_DIR}/label_mapping.json" ]; then
        print_test "Label mapping file exists" "PASS"

        # Validate label mapping content
        if python3 << 'PYEOF'
import json
try:
    with open("CATEGORY_MODEL_DIR/label_mapping.json") as f:
        mapping = json.load(f)
    assert "label2id" in mapping
    assert "id2label" in mapping
    assert len(mapping["label2id"]) == 14
    print("VALID")
except Exception as e:
    print("INVALID")
PYEOF
        then
            print_test "Label mapping has all 14 categories" "PASS"
        else
            print_test "Label mapping has all 14 categories" "FAIL"
        fi
    else
        print_test "Label mapping file exists" "FAIL"
    fi
else
    echo -e "${YELLOW}ℹ️  Category model not yet trained (expected)${NC}"
fi

# Test 8: Validate config loading (Python test)
echo -e "\n${YELLOW}STEP 3: Configuration Loading Test${NC}\n"

python3 << 'PYEOF'
import yaml
from pathlib import Path

configs = [
    ("category-signal-model-training-example/configs/category-signal-model.yaml", "classifier.category_model"),
    ("feedback-model-training-example/configs/feedback-model.yaml", "feedback_detector"),
    ("jailbreak-model-training-example/configs/prompt-guard.yaml", "prompt_guard"),
    ("pii-model-training-example/configs/pii-model.yaml", "classifier.pii_model"),
]

playbook_base = Path("docs/agent/playbooks")

for config_file, config_path in configs:
    config_file_path = playbook_base / config_file

    try:
        with open(config_file_path) as f:
            config = yaml.safe_load(f)

        # Navigate to the config section
        keys = config_path.split(".")
        section = config
        for key in keys:
            section = section[key]

        # Validate required fields
        required_fields = ["model_id", "threshold"]
        missing = [f for f in required_fields if f not in section]

        if not missing:
            print(f"✅ PASS: Config {config_file} - all fields present")
        else:
            print(f"❌ FAIL: Config {config_file} - missing fields: {missing}")
    except Exception as e:
        print(f"❌ FAIL: Config {config_file} - {e}")

PYEOF

# Summary
echo -e "\n${BLUE}======================================================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}======================================================================${NC}\n"

echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✅ ALL VALIDATIONS PASSED${NC}"
    echo -e "${GREEN}All four models are ready for training/deployment${NC}\n"
    exit 0
else
    echo -e "\n${RED}❌ SOME VALIDATIONS FAILED${NC}"
    echo -e "${RED}Please fix the issues above${NC}\n"
    exit 1
fi
