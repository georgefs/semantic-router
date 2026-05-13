#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"

MODEL_NAME="${MODEL_NAME:-llm-semantic-router/mmbert-32k-yarn}"
OUTPUT_DIR="${OUTPUT_DIR:-models/mmbert32k_feedback_detector_lora}"
DATA_SOURCE="${DATA_SOURCE:-llm-semantic-router/feedback-detector-dataset}"
MAX_SAMPLES="${MAX_SAMPLES:-}"
BATCH_SIZE="${BATCH_SIZE:-16}"
EPOCHS="${EPOCHS:-10}"
LR="${LR:-2e-5}"
LORA_RANK="${LORA_RANK:-64}"
LORA_ALPHA="${LORA_ALPHA:-128}"
USE_LORA="${USE_LORA:-true}"
MERGE_LORA="${MERGE_LORA:-true}"

ARGS=(
  --model_name "${MODEL_NAME}"
  --output_dir "${OUTPUT_DIR}"
  --data_source "${DATA_SOURCE}"
  --batch_size "${BATCH_SIZE}"
  --epochs "${EPOCHS}"
  --lr "${LR}"
  --lora_rank "${LORA_RANK}"
  --lora_alpha "${LORA_ALPHA}"
)

if [[ -n "${MAX_SAMPLES}" ]]; then
  ARGS+=(--max_samples "${MAX_SAMPLES}")
fi

if [[ "${USE_LORA}" == "true" ]]; then
  ARGS+=(--use_lora)
fi

if [[ "${MERGE_LORA}" == "true" ]]; then
  ARGS+=(--merge_lora)
fi

python "${REPO_ROOT}/src/training/model_classifier/user_feedback_classifier/train_feedback_detector.py" "${ARGS[@]}"
