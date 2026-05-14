# Manual Validation Guide - Model Training Examples

这份指南提供了手动验证所有四个模型训练示例的完整步骤。

## 📋 快速开始

### 1️⃣ 验证配置和文件结构

```bash
cd /home/test123/work/semantic-router

# 运行验证脚本
bash scripts/validate_all_models.sh
```

**预期输出**:
- ✅ 所有 4 个模型目录验证
- ✅ 配置文件有效
- ✅ YAML 语法正确
- ✅ 训练数据存在

### 2️⃣ 执行训练（可选）

```bash
# 只训练 Category Signal Model（推荐第一次运行）
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh

# 或者使用参数快速测试
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES_PER_CATEGORY=5 \
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh
```

### 3️⃣ 测试部署

```bash
bash scripts/test_deployment.sh
```

## 🔍 详细验证步骤

### 第 1 部分：基础验证

#### 1.1 验证 Category Signal Model

```bash
# 检查目录结构
ls -la docs/agent/playbooks/category-signal-model-training-example/

# 输出应该包含:
# README.md
# DEPLOYMENT_GUIDE.md
# configs/
# data/
# scripts/
# models/  (如果已训练)
```

```bash
# 验证配置文件
cat docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml

# 验证配置内容
python3 -c "
import yaml
with open('docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml') as f:
    config = yaml.safe_load(f)
    print('✅ Config valid')
    print('Model ID:', config['classifier']['category_model'].get('model_id'))
    print('Threshold:', config['classifier']['category_model'].get('threshold'))
"
```

#### 1.2 验证 Feedback Model

```bash
# 检查配置
python3 << 'EOF'
import yaml

with open('docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml') as f:
    config = yaml.safe_load(f)
    
    print("✅ Feedback config valid")
    print("  Enabled:", config['feedback_detector'].get('enabled'))
    print("  Model ID:", config['feedback_detector'].get('model_id'))
    print("  Threshold:", config['feedback_detector'].get('threshold'))
EOF
```

#### 1.3 验证 Jailbreak Model

```bash
# 检查配置
python3 << 'EOF'
import yaml

with open('docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml') as f:
    config = yaml.safe_load(f)
    
    print("✅ Jailbreak config valid")
    print("  Enabled:", config['prompt_guard'].get('enabled'))
    print("  Model ID:", config['prompt_guard'].get('model_id'))
    print("  Has mapping path:", 'jailbreak_mapping_path' in config['prompt_guard'])
EOF
```

#### 1.4 验证 PII Model

```bash
# 检查配置
python3 << 'EOF'
import yaml

with open('docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml') as f:
    config = yaml.safe_load(f)
    
    pii_config = config['classifier']['pii_model']
    print("✅ PII config valid")
    print("  Model ID:", pii_config.get('model_id'))
    print("  Threshold:", pii_config.get('threshold'))
    print("  Has PII mapping:", 'pii_mapping_path' in pii_config)
EOF
```

### 第 2 部分：训练验证

#### 2.1 快速训练 Category Model

```bash
cd /home/test123/work/semantic-router

# 快速测试（1 epoch, 少数样本）
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES_PER_CATEGORY=5 \
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh

# 预期输出：
# - Loading model: Qwen3-0.6B
# - Training: ~3-5 seconds
# - Model saved to: models/qwen3_generative_classifier_r8/
# - Validation accuracy: ~40-50% (expected for minimal training)
```

#### 2.2 完整训练 Category Model（可选）

```bash
# 默认参数（更好的准确率）
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh

# 或自定义参数
EPOCHS=10 LORA_RANK=32 MAX_SAMPLES_PER_CATEGORY=200 \
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh

# 预期：
# - Training time: 15-20 minutes
# - Accuracy: 70-85%
# - Model size: ~35MB
```

#### 2.3 验证模型输出

```bash
# 检查模型文件
ls -lah docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r8/

# 应该包含：
# - adapter_model.safetensors (20MB) - LoRA权重
# - label_mapping.json (1.2K) - Category映射
# - tokenizer.json (11MB) - 分词器
# - 其他配置文件

# 验证 label_mapping 内容
python3 << 'EOF'
import json

with open('docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r8/label_mapping.json') as f:
    mapping = json.load(f)
    
    print(f"✅ Label mapping valid")
    print(f"   Categories: {len(mapping['label2id'])}")
    
    for i, (cat, idx) in enumerate(list(mapping['label2id'].items())[:5]):
        print(f"   - {cat} → {idx}")
    print("   ...")
EOF
```

### 第 3 部分：部署验证

#### 3.1 测试配置加载

```bash
cd /home/test123/work/semantic-router

# 测试所有配置都能被加载
python3 << 'EOF'
import yaml
from pathlib import Path

configs = [
    "docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml",
    "docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml",
    "docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml",
    "docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml",
]

print("Testing configuration loading...\n")

for config_file in configs:
    try:
        with open(config_file) as f:
            config = yaml.safe_load(f)
        print(f"✅ {Path(config_file).parent.parent.name}")
    except Exception as e:
        print(f"❌ {config_file}: {e}")
EOF
```

#### 3.2 测试模型推理（如果已训练）

```bash
# 测试 category 模型推理
python3 src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py \
  --mode test \
  --model-path docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r8

# 预期输出：
# Loading model...
# Running inference...
# Q: What is corporate mergers → business ✓
# Q: What is legal requirements → law ✓
# ...
```

#### 3.3 运行完整部署测试

```bash
bash scripts/test_deployment.sh

# 预期输出：
# ✅ Configuration Loading
# ✅ Model Files Validation
# ✅ Label Mapping Validation
# ✅ Runtime Configuration Compatibility
# ✅ Category Model Inference (if trained)
```

## 📊 验证检查清单

```
基础验证:
[ ] 所有 4 个模型目录存在
[ ] 所有配置文件有效 YAML
[ ] 所有训练数据文件存在
[ ] 所有训练脚本可执行

配置验证:
[ ] Category config 包含 14 categories
[ ] Feedback config 包含 4-class 设置
[ ] Jailbreak config 包含 mapping path
[ ] PII config 包含 PII entity types

训练验证（可选）:
[ ] Category model 训练成功
[ ] 模型文件输出正确
[ ] label_mapping.json 包含所有 categories
[ ] 推理结果正确

部署验证:
[ ] 所有配置能被加载
[ ] 模型路径正确解析
[ ] Runtime 初始化成功
[ ] 推理测试通过
```

## 🚀 完整验证流程

```bash
#!/bin/bash
# Run this script to perform complete validation

cd /home/test123/work/semantic-router

echo "Step 1: Validate configurations..."
bash scripts/validate_all_models.sh

echo -e "\nStep 2: Train category model..."
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES_PER_CATEGORY=5 \
bash docs/agent/playbooks/category-signal-model-training-example/scripts/train_qwen3_generative_lora.sh

echo -e "\nStep 3: Test deployment..."
bash scripts/test_deployment.sh

echo -e "\n✅ Complete validation finished!"
```

## 🔧 故障排除

### 问题 1: YAML 解析错误

```bash
# 验证 YAML 语法
python3 -m yaml <config-file>

# 或使用 online validator
# https://www.yamllint.com
```

### 问题 2: 模型文件找不到

```bash
# 检查模型目录
find . -name "adapter_model.safetensors"

# 检查配置中的路径是否正确
grep -n "model_path\|label_mapping" <config-file>
```

### 问题 3: 推理失败

```bash
# 检查 label_mapping.json 是否有效
python3 -c "import json; json.load(open('<path>/label_mapping.json'))"

# 检查模型权重文件大小（应该是 ~20MB）
ls -lh <model-dir>/adapter_model.safetensors
```

## 📞 获取帮助

如果在验证过程中遇到问题：

1. 检查 README.md 中的详细说明
2. 查看训练脚本的注释
3. 查看配置文件中的注释
4. 运行单个验证命令（不是整个脚本）

## ✅ 验证完成标志

当您看到以下输出时，验证就完成了：

```
======================================================================
✅ ALL DEPLOYMENT TESTS PASSED
Ready for production deployment
======================================================================
```

---

**最后更新**: 2026-05-13
