#!/usr/bin/env bash
# Validate that all models are configured for MoM (Mixture of Models) architecture
# with mmBERT-32K as the unified base model

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========================================================================"
echo "MoM Architecture Validation"
echo "========================================================================"
echo ""
echo "Checking that all models use mmBERT-32K base model..."
echo ""

PASS=0
FAIL=0

check_config() {
    local config_file="$1"
    local model_name="$2"

    if [ ! -f "$config_file" ]; then
        echo "❌ FAIL: $model_name config not found: $config_file"
        ((FAIL++))
        return 1
    fi

    # Check for use_mmbert_32k: true
    if grep -q "use_mmbert_32k: true" "$config_file" 2>/dev/null; then
        echo "✅ PASS: $model_name has use_mmbert_32k: true"
        ((PASS++))
        return 0
    else
        echo "❌ FAIL: $model_name missing use_mmbert_32k: true"
        echo "   File: $config_file"
        ((FAIL++))
        return 1
    fi
}

# Validate Category Model
check_config \
    "${REPO_ROOT}/docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml" \
    "Category Signal Model" || true

# Validate Feedback Model
check_config \
    "${REPO_ROOT}/docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml" \
    "Feedback Detector" || true

# Validate Jailbreak Model
check_config \
    "${REPO_ROOT}/docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml" \
    "Jailbreak Detector" || true

# Validate PII Model
check_config \
    "${REPO_ROOT}/docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml" \
    "PII Detector" || true

echo ""
echo "========================================================================"
echo "Training Scripts Validation"
echo "========================================================================"
echo ""

# Check Category training script has mmBERT support
if [ -f "${REPO_ROOT}/docs/agent/playbooks/category-signal-model-training-example/scripts/train_category_classifier_mmbert_lora.py" ]; then
    echo "✅ PASS: Category mmBERT training script exists"
    ((PASS++))
else
    echo "❌ FAIL: Category mmBERT training script not found"
    ((FAIL++))
fi

# Check Jailbreak script uses mmBERT-32K
if grep -q "mmbert-32k\|mmBERT-32K" "${REPO_ROOT}/docs/agent/playbooks/jailbreak-model-training-example/scripts/train_jailbreak_lora_cpu.sh" 2>/dev/null; then
    echo "✅ PASS: Jailbreak script uses mmBERT-32K"
    ((PASS++))
else
    echo "❌ FAIL: Jailbreak script not using mmBERT-32K"
    ((FAIL++))
fi

echo ""
echo "========================================================================"
echo "Summary"
echo "========================================================================"
echo ""
echo "✅ Passed: $PASS"
echo "❌ Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✅ All checks passed! MoM architecture is correctly configured."
    echo ""
    echo "All 4 models now use mmBERT-32K as the unified base model:"
    echo "  1. Category Signal Model → mmbert32k_category_classifier"
    echo "  2. Feedback Detector → mmbert32k_feedback_detector"
    echo "  3. Jailbreak Detector → mmbert32k_jailbreak_detector"
    echo "  4. PII Detector → mmbert32k_pii_detector"
    echo ""
    exit 0
else
    echo "❌ Some checks failed. Please fix the issues above."
    exit 1
fi
