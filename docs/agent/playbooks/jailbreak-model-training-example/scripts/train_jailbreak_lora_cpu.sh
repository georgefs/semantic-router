#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"

MODEL="${MODEL:-bert-base-uncased}"
EPOCHS="${EPOCHS:-8}"
LORA_RANK="${LORA_RANK:-8}"
LORA_ALPHA="${LORA_ALPHA:-16}"
MAX_SAMPLES="${MAX_SAMPLES:-7000}"
BATCH_SIZE="${BATCH_SIZE:-2}"
LEARNING_RATE="${LEARNING_RATE:-3e-5}"
QUICK="${QUICK:-false}"

ARGS=(
  --mode train
  --model "${MODEL}"
  --epochs "${EPOCHS}"
  --lora-rank "${LORA_RANK}"
  --lora-alpha "${LORA_ALPHA}"
  --max-samples "${MAX_SAMPLES}"
  --batch-size "${BATCH_SIZE}"
  --learning-rate "${LEARNING_RATE}"
)

if [[ "${QUICK}" == "true" ]]; then
  ARGS+=(--epochs 1 --max-samples 50)
fi

python "${REPO_ROOT}/src/training/model_classifier/prompt_guard_fine_tuning_lora/jailbreak_bert_finetuning_lora.py" "${ARGS[@]}"
