#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"

MODE="${MODE:-train}"
MODEL="${MODEL:-mmbert-32k}"
EPOCHS="${EPOCHS:-8}"
LORA_RANK="${LORA_RANK:-8}"
LORA_ALPHA="${LORA_ALPHA:-16}"
LORA_DROPOUT="${LORA_DROPOUT:-0.1}"
MAX_SAMPLES="${MAX_SAMPLES:-7000}"
BATCH_SIZE="${BATCH_SIZE:-2}"
LEARNING_RATE="${LEARNING_RATE:-3e-5}"
USE_AI4PRIVACY="${USE_AI4PRIVACY:-true}"

ARGS=(
  --mode "${MODE}"
  --model "${MODEL}"
  --epochs "${EPOCHS}"
  --lora-rank "${LORA_RANK}"
  --lora-alpha "${LORA_ALPHA}"
  --lora-dropout "${LORA_DROPOUT}"
  --max-samples "${MAX_SAMPLES}"
  --batch-size "${BATCH_SIZE}"
  --learning-rate "${LEARNING_RATE}"
)

if [[ "${USE_AI4PRIVACY}" == "true" ]]; then
  ARGS+=(--use-ai4privacy)
else
  ARGS+=(--no-ai4privacy)
fi

python "${REPO_ROOT}/src/training/model_classifier/pii_model_fine_tuning_lora/pii_bert_finetuning_lora.py" "${ARGS[@]}"
