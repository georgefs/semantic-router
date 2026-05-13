#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"

python "${REPO_ROOT}/src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py" \
  --mode train \
  --epochs "${EPOCHS:-8}" \
  --lora-rank "${LORA_RANK:-16}" \
  --max-samples-per-category "${MAX_SAMPLES_PER_CATEGORY:-150}" \
  --gpu-id "${GPU_ID:-0}"
