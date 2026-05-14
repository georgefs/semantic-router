#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
PLAYBOOK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# MoM Architecture: Use mmBERT-32K as base model (unified with Feedback, PII, Jailbreak)
# For backward compatibility, support both Qwen3 and mmBERT training
MODEL_TYPE="${MODEL_TYPE:-mmbert}"
MODEL_NAME="${MODEL_NAME:-llm-semantic-router/mmbert-32k-yarn}"
LORA_RANK="${LORA_RANK:-16}"
EPOCHS="${EPOCHS:-8}"

# Set default output directory based on model type
if [[ "${MODEL_TYPE}" == "mmbert" ]]; then
  OUTPUT_DIR="${OUTPUT_DIR:-${PLAYBOOK_DIR}/models/mmbert32k_category_classifier_r${LORA_RANK}}"
  PYTHON_SCRIPT="train_category_classifier_mmbert_lora.py"
else
  OUTPUT_DIR="${OUTPUT_DIR:-${PLAYBOOK_DIR}/models/qwen3_generative_classifier_r${LORA_RANK}}"
  PYTHON_SCRIPT="ft_qwen3_generative_lora.py"
fi

mkdir -p "$(dirname "${OUTPUT_DIR}")"

# Determine full path to training script
if [[ -f "${SCRIPT_DIR}/${PYTHON_SCRIPT}" ]]; then
  # Same directory as shell script
  TRAIN_SCRIPT="${SCRIPT_DIR}/${PYTHON_SCRIPT}"
elif [[ -f "${REPO_ROOT}/src/training/model_classifier/classifier_model_fine_tuning_lora/${PYTHON_SCRIPT}" ]]; then
  # Standard location for mmBERT script
  TRAIN_SCRIPT="${REPO_ROOT}/src/training/model_classifier/classifier_model_fine_tuning_lora/${PYTHON_SCRIPT}"
else
  # Fallback to original Qwen3 script
  TRAIN_SCRIPT="${REPO_ROOT}/src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py"
fi

python "${TRAIN_SCRIPT}" \
  --mode train \
  --model-name "${MODEL_NAME}" \
  --epochs "${EPOCHS}" \
  --lora-rank "${LORA_RANK}" \
  --max-samples-per-category "${MAX_SAMPLES_PER_CATEGORY:-150}" \
  --gpu-id "${GPU_ID:-0}" \
  --output-dir "${OUTPUT_DIR}" \
  --batch-size "${BATCH_SIZE:-16}" \
  --learning-rate "${LR:-2e-5}"
