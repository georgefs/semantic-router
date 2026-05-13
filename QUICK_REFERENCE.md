# 快速参考 - 模型训练和部署命令

直接复制粘贴这些命令进行验证。

## 🚀 快速开始 (5分钟)

```bash
# 1. 进入项目目录
cd /home/test123/work/semantic-router

# 2. 验证所有配置
bash scripts/validate_all_models.sh

# 3. 快速训练 category model (1 epoch, 3-5 秒)
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES_PER_CATEGORY=5 \
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh

# 4. 测试部署
bash scripts/test_deployment.sh

# 完成！✅
```

---

## 📋 按模型逐一验证

### Category Signal Model

```bash
cd /home/test123/work/semantic-router

# 验证配置
python3 -c "
import yaml
with open('docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml') as f:
    config = yaml.safe_load(f)
    cat_config = config['classifier']['category_model']
    print('✅ Config Valid')
    print(f\"  Model ID: {cat_config['model_id']}\")
    print(f\"  Threshold: {cat_config['threshold']}\")
    print(f\"  Fallback: {cat_config['fallback_category']}\")
"

# 验证数据
wc -l docs/agent/playbooks/category-signal-model-training-example/data/training-samples.jsonl

# 训练模型
# 快速版 (1 epoch, 5分钟)
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES_PER_CATEGORY=5 \
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh

# 或完整版 (10 epochs, 20分钟)
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh

# 验证模型输出
ls -lah docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r*/

# 测试推理
python3 src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py \
  --mode test \
  --model-path docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r8
```

### Feedback Model

```bash
cd /home/test123/work/semantic-router

# 验证配置
python3 -c "
import yaml
with open('docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml') as f:
    config = yaml.safe_load(f)
    print('✅ Feedback Config Valid')
    print(f\"  Enabled: {config['feedback_detector']['enabled']}\")
    print(f\"  Model ID: {config['feedback_detector']['model_id']}\")
"

# 验证数据
wc -l docs/agent/playbooks/feedback-model-training-example/data/training-samples.jsonl

# 查看样本
head -3 docs/agent/playbooks/feedback-model-training-example/data/training-samples.jsonl
```

### Jailbreak Model

```bash
cd /home/test123/work/semantic-router

# 验证配置
python3 -c "
import yaml
with open('docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml') as f:
    config = yaml.safe_load(f)
    print('✅ Jailbreak Config Valid')
    print(f\"  Model ID: {config['prompt_guard']['model_id']}\")
    print(f\"  Has mapping: {'jailbreak_mapping_path' in config['prompt_guard']}\")
"

# 验证数据
wc -l docs/agent/playbooks/jailbreak-model-training-example/data/training-samples.jsonl
```

### PII Model

```bash
cd /home/test123/work/semantic-router

# 验证配置
python3 -c "
import yaml
with open('docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml') as f:
    config = yaml.safe_load(f)
    pii_config = config['classifier']['pii_model']
    print('✅ PII Config Valid')
    print(f\"  Model ID: {pii_config['model_id']}\")
    print(f\"  Has mapping: {'pii_mapping_path' in pii_config}\")
"

# 验证数据
wc -l docs/agent/playbooks/pii-model-training-example/data/training-samples.jsonl
```

---

## 🔍 详细验证

### 验证所有配置文件格式

```bash
cd /home/test123/work/semantic-router

python3 << 'EOF'
import yaml
import sys

configs = [
    ("Category", "docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml"),
    ("Feedback", "docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml"),
    ("Jailbreak", "docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml"),
    ("PII", "docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml"),
]

print("Validating all configurations...\n")

for name, path in configs:
    try:
        with open(path) as f:
            config = yaml.safe_load(f)
        print(f"✅ {name:12} - Valid YAML, {len(str(config))} bytes")
    except Exception as e:
        print(f"❌ {name:12} - {e}")
        sys.exit(1)

print("\n✅ All configurations are valid")
EOF
```

### 验证模型文件完整性

```bash
cd /home/test123/work/semantic-router

python3 << 'EOF'
import os
from pathlib import Path

model_dirs = [
    "docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r8",
    "docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r16",
]

required_files = [
    "adapter_model.safetensors",
    "label_mapping.json",
    "tokenizer.json",
    "adapter_config.json",
]

for model_dir in model_dirs:
    if os.path.exists(model_dir):
        print(f"\nChecking {Path(model_dir).name}:")
        for file in required_files:
            path = os.path.join(model_dir, file)
            if os.path.exists(path):
                size = os.path.getsize(path) / (1024 * 1024)  # MB
                print(f"  ✓ {file:30} ({size:.1f} MB)")
            else:
                print(f"  ✗ {file:30} (missing)")
EOF
```

### 验证 Label Mapping

```bash
cd /home/test123/work/semantic-router

python3 << 'EOF'
import json
from pathlib import Path

label_mapping_path = Path("docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r8/label_mapping.json")

if label_mapping_path.exists():
    with open(label_mapping_path) as f:
        mapping = json.load(f)
    
    print("Label Mapping Summary:")
    print(f"  Categories: {len(mapping['label2id'])}")
    print(f"  Sample categories:")
    for i, (cat, idx) in enumerate(list(mapping['label2id'].items())[:5]):
        print(f"    - {cat} → {idx}")
else:
    print("Label mapping not found (model not trained yet)")
EOF
```

---

## 🧪 测试脚本

### 快速测试（推荐）

```bash
cd /home/test123/work/semantic-router
bash scripts/test_deployment.sh
```

### 完整验证套件

```bash
cd /home/test123/work/semantic-router

# 1. 验证配置
echo "=== Step 1: Validate Configurations ==="
bash scripts/validate_all_models.sh

# 2. 快速训练
echo -e "\n=== Step 2: Quick Training ==="
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES_PER_CATEGORY=5 \
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh

# 3. 部署测试
echo -e "\n=== Step 3: Deployment Test ==="
bash scripts/test_deployment.sh

echo -e "\n✅ Complete validation finished!"
```

---

## 📊 预期输出

### 验证脚本输出

```
======================================================================
Model Training Examples - Complete Validation Script
======================================================================

[TEST] Directory exists: category-signal-model-training-example
✅ PASS: Directory exists

[TEST] Config file exists: category-signal-model.yaml
✅ PASS: Config file exists
         File size: 2841 bytes

[TEST] YAML syntax valid
✅ PASS: YAML syntax valid

...

✅ ALL VALIDATIONS PASSED
All four models are ready for training/deployment
```

### 训练脚本输出

```
2026-05-13 22:14:58 - INFO - Loading dataset from HuggingFace
...
2026-05-13 22:15:21 - INFO - Starting training...
100%|████████████████████████████| 3/3 [00:03<00:00,  1.09s/it]
2026-05-13 22:15:25 - INFO - Model saved to: .../models/qwen3_generative_classifier_r8

Testing generation on MMLU-Pro validation data:
==================================================
Validation Accuracy: 6/14 = 42.86%
==================================================
```

### 部署测试输出

```
TEST 1: Configuration Loading
✅ PASS: Category Signal config loaded successfully
✅ PASS: Feedback config loaded successfully
...

TEST 2: Model Files Validation
✅ PASS: Model directory exists
  ✓ adapter_model.safetensors
  ✓ label_mapping.json
  ✓ tokenizer.json

✅ ALL DEPLOYMENT TESTS PASSED
Ready for production deployment
```

---

## 🐛 常见问题快速修复

| 问题 | 命令 |
|------|------|
| 确认 Python 环境 | `python3 --version` |
| 检查依赖 | `pip list \| grep -E "peft\|transformers\|torch"` |
| 验证 YAML 格式 | `python3 -m yaml <file>` |
| 查看模型文件大小 | `du -sh docs/agent/playbooks/*/models/*/` |
| 检查 GPU 可用性 | `nvidia-smi` |
| 使用 CPU 训练 | `GPU_ID=-1 bash ...train*.sh` |

---

**快速验证时间**: ~5-15 分钟  
**完整验证时间**: ~20-30 分钟（包括训练）

