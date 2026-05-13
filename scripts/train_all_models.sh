#!/usr/bin/env bash
# Train All Model Examples Script
# Executes training for all four model examples with verification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PLAYBOOK_BASE="${REPO_ROOT}/docs/agent/playbooks"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}Training All Model Examples${NC}"
echo -e "${BLUE}======================================================================${NC}\n"

# Function to train a model
train_model() {
    local model_name="$1"
    local script_name="$2"
    local description="$3"

    echo -e "\n${YELLOW}Training: $model_name${NC}"
    echo -e "Purpose: $description\n"

    local model_path="${PLAYBOOK_BASE}/${model_name}"
    local script_path="${model_path}/scripts/${script_name}"

    if [ ! -f "$script_path" ]; then
        echo -e "${RED}❌ Script not found: $script_path${NC}"
        return 1
    fi

    # Run training
    cd "$model_path"
    echo "Executing: $script_name"
    echo "Working directory: $(pwd)"
    echo ""

    if bash "scripts/${script_name}"; then
        echo -e "\n${GREEN}✅ Training completed: $model_name${NC}"
        return 0
    else
        echo -e "\n${YELLOW}⚠️ Training finished with warnings/errors${NC}"
        return 1
    fi
}

# Step 1: Validate before training
echo -e "${YELLOW}STEP 1: Pre-Training Validation${NC}\n"
cd "$REPO_ROOT"
if bash scripts/validate_all_models.sh; then
    echo -e "\n${GREEN}✅ All validations passed${NC}"
else
    echo -e "\n${YELLOW}⚠️ Some validations failed, continuing anyway${NC}"
fi

# Step 2: Train Category Model (Full training)
echo -e "\n${YELLOW}STEP 2: Training Category Signal Model${NC}"
echo -e "${BLUE}==========================================${NC}"

train_model \
    "category-signal-model-training-example" \
    "train_qwen3_generative_lora.sh" \
    "Domain/Category classification (14 classes)"

# Step 3: Train Feedback Model (Optional)
echo -e "\n${YELLOW}STEP 3: Training Feedback Detector Model (Optional)${NC}"
echo -e "${BLUE}==========================================${NC}"

if [ "${TRAIN_FEEDBACK:-false}" = "true" ]; then
    train_model \
        "feedback-model-training-example" \
        "train_feedback_detector_lora.sh" \
        "User feedback classification (4-class)"
else
    echo -e "${YELLOW}Skipping feedback model training (set TRAIN_FEEDBACK=true to enable)${NC}"
fi

# Step 4: Train Jailbreak Model (Optional)
echo -e "\n${YELLOW}STEP 4: Training Jailbreak Detector Model (Optional)${NC}"
echo -e "${BLUE}==========================================${NC}"

if [ "${TRAIN_JAILBREAK:-false}" = "true" ]; then
    train_model \
        "jailbreak-model-training-example" \
        "train_jailbreak_lora_cpu.sh" \
        "Security detection (safe/jailbreak)"
else
    echo -e "${YELLOW}Skipping jailbreak model training (set TRAIN_JAILBREAK=true to enable)${NC}"
fi

# Step 5: Train PII Model (Optional)
echo -e "\n${YELLOW}STEP 5: Training PII Detector Model (Optional)${NC}"
echo -e "${BLUE}==========================================${NC}"

if [ "${TRAIN_PII:-false}" = "true" ]; then
    train_model \
        "pii-model-training-example" \
        "train_pii_lora_cpu.sh" \
        "PII entity extraction"
else
    echo -e "${YELLOW}Skipping PII model training (set TRAIN_PII=true to enable)${NC}"
fi

# Step 6: Post-training validation
echo -e "\n${YELLOW}STEP 6: Post-Training Validation${NC}"
echo -e "${BLUE}==========================================${NC}\n"

cd "$REPO_ROOT"
bash scripts/validate_all_models.sh

echo -e "\n${BLUE}======================================================================${NC}"
echo -e "${GREEN}✅ Training Complete${NC}"
echo -e "${BLUE}======================================================================${NC}\n"

echo "Next steps:"
echo "1. Review model outputs in the respective models/ directories"
echo "2. Run deployment verification: bash scripts/test_deployment.sh"
echo "3. Start semantic-router with the trained models"
echo ""
