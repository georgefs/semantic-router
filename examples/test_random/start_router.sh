  VLLM_SR_STACK_NAME=random-signal \
  VLLM_SR_PORT_OFFSET=3100 \
  VLLM_SR_STATE_ROOT_DIR="$(pwd)" \
  vllm-sr serve --image-pull-policy never --config ./random-signal.yaml
