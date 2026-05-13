# ModernBERT-base MoM 設置完整指南

**目標**: 將所有 4 個分類模型改為使用 **ModernBERT-base** 作為統一基礎模型（MoM 架構）

---

## 📋 概述

| 項目 | mmBERT-32K | ModernBERT-base |
|------|-----------|-----------------|
| **大小** | 309 MB | 300 MB |
| **上下文** | 32K tokens | 8K tokens |
| **多語言** | ✅ 500+ | ❌ 英文主要 |
| **架構** | 多語言 ModernBERT | 標準 ModernBERT |
| **推薦** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

**何時使用 ModernBERT-base?**
- ✅ 英文應用為主
- ✅ 想要最新的 ModernBERT 架構
- ✅ 8K 上下文足夠
- ❌ 需要多語言（用 mmBERT-base）
- ❌ 需要長上下文（用 mmBERT-32K）

---

## 🚀 Step 1: 訓練 ModernBERT-base 模型

### 1.1 快速訓練（測試）

```bash
cd /home/test123/work/semantic-router

# Category Signal Model
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES=50 \
python src/training/model_classifier/classifier_model_fine_tuning_lora/ft_linear_lora.py \
  --mode train \
  --model modernbert-base \
  --output-dir models/modernbert_category_classifier_r8

# Jailbreak Detector
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES=50 \
python src/training/model_classifier/prompt_guard_fine_tuning_lora/jailbreak_bert_finetuning_lora.py \
  --mode train \
  --model modernbert-base \
  --output-dir models/modernbert_jailbreak_classifier_r8

# PII Detector
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES=50 \
python src/training/model_classifier/pii_model_fine_tuning_lora/pii_bert_finetuning_lora.py \
  --mode train \
  --model modernbert-base \
  --output-dir models/modernbert_pii_detector_r8

# Feedback Detector
EPOCHS=1 LORA_RANK=8 MAX_SAMPLES=50 \
python src/training/model_classifier/feedback_detector_fine_tuning_lora/feedback_bert_finetuning_lora.py \
  --mode train \
  --model modernbert-base \
  --output-dir models/modernbert_feedback_detector_r8
```

**時間**: ~4-6 秒 (每個模型)

### 1.2 完整訓練（生產）

```bash
# Category Signal Model
python src/training/model_classifier/classifier_model_fine_tuning_lora/ft_linear_lora.py \
  --mode train \
  --model modernbert-base \
  --epochs 8 \
  --lora-rank 16 \
  --max-samples 2000 \
  --output-dir models/modernbert_category_classifier_r16

# Jailbreak Detector
python src/training/model_classifier/prompt_guard_fine_tuning_lora/jailbreak_bert_finetuning_lora.py \
  --mode train \
  --model modernbert-base \
  --epochs 8 \
  --lora-rank 16 \
  --max-samples 1000 \
  --output-dir models/modernbert_jailbreak_classifier_r16

# PII Detector
python src/training/model_classifier/pii_model_fine_tuning_lora/pii_bert_finetuning_lora.py \
  --mode train \
  --model modernbert-base \
  --epochs 8 \
  --lora-rank 16 \
  --max-samples 10000 \
  --output-dir models/modernbert_pii_detector_r16

# Feedback Detector
python src/training/model_classifier/feedback_detector_fine_tuning_lora/feedback_bert_finetuning_lora.py \
  --mode train \
  --model modernbert-base \
  --epochs 8 \
  --lora-rank 16 \
  --max-samples 1000 \
  --output-dir models/modernbert_feedback_detector_r16
```

**時間**: ~20-30 分鐘 (所有 4 個模型)

---

## 📝 Step 2: 更新配置文件

### 2.1 category-signal-model.yaml

```yaml
classifier:
  category_model:
    model_id: "modernbert_category_classifier"
    threshold: 0.75
    use_cpu: true
    use_modernbert: true      # ← 改為 true
    use_mmbert_32k: false     # ← 改為 false
    category_mapping_path: "models/modernbert_category_classifier_r16/category_mapping.json"
    fallback_category: "other"

categories:
  - name: "law"
    # ... 其他配置
```

### 2.2 prompt-guard.yaml

```yaml
prompt_guard:
  enabled: true
  model_id: "models/modernbert_jailbreak_classifier"
  threshold: 0.7
  use_cpu: true
  use_modernbert: true       # ← 改為 true
  use_mmbert_32k: false      # ← 改為 false
  jailbreak_mapping_path: "models/modernbert_jailbreak_classifier/jailbreak_type_mapping.json"
```

### 2.3 pii-model.yaml

```yaml
classifier:
  pii_model:
    model_id: "models/modernbert_pii_detector"
    threshold: 0.7
    use_cpu: true
    use_modernbert: true     # ← 改為 true
    use_mmbert_32k: false    # ← 改為 false
    pii_mapping_path: "models/modernbert_pii_detector/pii_type_mapping.json"
```

### 2.4 feedback-model.yaml

```yaml
feedback_detector:
  enabled: true
  model_id: "models/modernbert_feedback_detector"
  threshold: 0.7
  use_cpu: true
  use_modernbert: true      # ← 改為 true
  use_mmbert_32k: false     # ← 改為 false
```

---

## ✅ Step 3: 驗證配置

### 3.1 檢查所有配置

```bash
# 驗證所有配置使用 ModernBERT
python3 << 'EOF'
import yaml
from pathlib import Path

configs = [
    "docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml",
    "docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml",
    "docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml",
    "docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml",
]

print("Checking ModernBERT configuration...\n")

all_pass = True
for config_path in configs:
    with open(config_path) as f:
        config = yaml.safe_load(f)
    
    # Get the model config (varies by file)
    if "category_model" in config.get("classifier", {}):
        model_cfg = config["classifier"]["category_model"]
    elif "pii_model" in config.get("classifier", {}):
        model_cfg = config["classifier"]["pii_model"]
    elif "prompt_guard" in config:
        model_cfg = config["prompt_guard"]
    elif "feedback_detector" in config:
        model_cfg = config["feedback_detector"]
    else:
        continue
    
    model_name = Path(config_path).parent.parent.name
    
    modernbert = model_cfg.get("use_modernbert", False)
    mmbert32k = model_cfg.get("use_mmbert_32k", False)
    
    if modernbert and not mmbert32k:
        print(f"✅ {model_name:40} use_modernbert=true, use_mmbert_32k=false")
    else:
        print(f"❌ {model_name:40} use_modernbert={modernbert}, use_mmbert_32k={mmbert32k}")
        all_pass = False

print()
if all_pass:
    print("✅ All configurations correct for ModernBERT MoM!")
else:
    print("❌ Some configurations need adjustment")
EOF
```

### 3.2 檢查模型文件

```bash
# 確認所有模型文件都存在
ls -lh models/modernbert_*_r16/adapter_model.safetensors 2>/dev/null || echo "Models not found"

# 檢查模型大小
du -sh models/modernbert_* 2>/dev/null | tail -5
```

---

## 🔄 Step 4: 驗證 MoM 架構

### 4.1 創建驗證腳本

```bash
cat > scripts/validate_modernbert_mom.sh << 'EOF'
#!/bin/bash

echo "=========================================================================="
echo "ModernBERT MoM Architecture Validation"
echo "=========================================================================="
echo

PASS=0
FAIL=0

# Check configs
echo "Checking ModernBERT configurations..."
echo

configs=(
    "docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml"
    "docs/agent/playbooks/feedback-model-training-example/configs/feedback-model.yaml"
    "docs/agent/playbooks/jailbreak-model-training-example/configs/prompt-guard.yaml"
    "docs/agent/playbooks/pii-model-training-example/configs/pii-model.yaml"
)

for config in "${configs[@]}"; do
    model_name=$(basename $(dirname $(dirname $config)))
    
    if grep -q "use_modernbert: true" "$config" && grep -q "use_mmbert_32k: false" "$config"; then
        echo "✅ PASS: $model_name"
        ((PASS++))
    else
        echo "❌ FAIL: $model_name"
        ((FAIL++))
    fi
done

echo
echo "=========================================================================="
echo "Results: $PASS passed, $FAIL failed"
echo "=========================================================================="

if [ $FAIL -eq 0 ]; then
    echo "✅ ModernBERT MoM architecture is correctly configured!"
    exit 0
else
    echo "❌ Some configurations need adjustment"
    exit 1
fi
EOF

chmod +x scripts/validate_modernbert_mom.sh
bash scripts/validate_modernbert_mom.sh
```

---

## 📊 配置對比

### 現在 (mmBERT-32K)
```yaml
use_mmbert_32k: true
use_modernbert: false
```

### 改為 ModernBERT
```yaml
use_mmbert_32k: false
use_modernbert: true
```

### 同時設置兩個是錯誤的 ❌
```yaml
use_mmbert_32k: true
use_modernbert: true
# ❌ 互斥! 只能選一個
```

---

## 🔧 高級配置選項

### 調整 LoRA 參數

```bash
# 快速版本 (低精度)
LORA_RANK=8 \
python train.py --model modernbert-base

# 平衡版本 (推薦)
LORA_RANK=16 \
python train.py --model modernbert-base

# 高精度版本 (更慢)
LORA_RANK=32 \
python train.py --model modernbert-base
```

### 調整超參數

```bash
# 快速訓練
python train.py \
  --model modernbert-base \
  --epochs 1 \
  --batch-size 4 \
  --learning-rate 5e-4 \
  --max-samples 50

# 完整訓練
python train.py \
  --model modernbert-base \
  --epochs 8 \
  --batch-size 16 \
  --learning-rate 3e-4 \
  --max-samples 2000
```

---

## 📈 性能預期

### 與 mmBERT-32K 對比

| 指標 | mmBERT-32K | ModernBERT-base |
|------|-----------|-----------------|
| **推理速度** | 100ms | 90-100ms (稍快) |
| **精度** | 較好 | 相近 |
| **上下文** | 32K | 8K |
| **多語言** | ✅ | ❌ |
| **內存** | 309 MB | 300 MB |
| **LoRA 大小** | 6-7 MB | 6-7 MB |

**結論**: 性能相近，但上下文更短

---

## ⚠️ 注意事項

### 1. 互斥標誌
```yaml
# ❌ 錯誤: 同時為 true
use_mmbert_32k: true
use_modernbert: true

# ✅ 正確: 只有一個為 true
use_mmbert_32k: false
use_modernbert: true
```

### 2. 模型路徑
確保 `model_id` 指向正確的 ModernBERT 模型:
```yaml
model_id: "modernbert_category_classifier"  # ✅ 正確
model_id: "mmbert32k_category_classifier"   # ❌ 錯誤
```

### 3. 標籤映射
確保標籤映射文件存在:
```bash
ls models/modernbert_*/category_mapping.json   # Category
ls models/modernbert_*/jailbreak_type_mapping.json  # Jailbreak
ls models/modernbert_*/pii_type_mapping.json  # PII
```

### 4. 上下文限制
ModernBERT-base 的上下文是 8K tokens:
```
512 tokens    : BERT-base, RoBERTa-base
8K tokens     : ModernBERT-base, mmBERT-base ⚠️
32K tokens    : mmBERT-32K ✅
```

如果經常遇到超過 8K tokens 的輸入，需要改回 mmBERT-32K。

---

## 🚀 完整遷移步驟（一鍵）

```bash
#!/bin/bash
set -euo pipefail

cd /home/test123/work/semantic-router

# Step 1: Train all ModernBERT models
echo "🚀 Training ModernBERT models..."

EPOCHS=1 LORA_RANK=8 MAX_SAMPLES=50 \
python src/training/model_classifier/classifier_model_fine_tuning_lora/ft_linear_lora.py \
  --mode train --model modernbert-base

EPOCHS=1 LORA_RANK=8 MAX_SAMPLES=50 \
python src/training/model_classifier/prompt_guard_fine_tuning_lora/jailbreak_bert_finetuning_lora.py \
  --mode train --model modernbert-base

EPOCHS=1 LORA_RANK=8 MAX_SAMPLES=50 \
python src/training/model_classifier/pii_model_fine_tuning_lora/pii_bert_finetuning_lora.py \
  --mode train --model modernbert-base

EPOCHS=1 LORA_RANK=8 MAX_SAMPLES=50 \
python src/training/model_classifier/feedback_detector_fine_tuning_lora/feedback_bert_finetuning_lora.py \
  --mode train --model modernbert-base

echo "✅ Training complete!"

# Step 2: Update configurations
echo "📝 Updating configurations..."

# Update all yaml files to use ModernBERT
sed -i 's/use_mmbert_32k: true/use_mmbert_32k: false/g' \
  docs/agent/playbooks/*/configs/*.yaml

sed -i 's/use_modernbert: false/use_modernbert: true/g' \
  docs/agent/playbooks/*/configs/*.yaml

echo "✅ Configurations updated!"

# Step 3: Validate
echo "✅ Validating ModernBERT MoM setup..."
bash scripts/validate_modernbert_mom.sh

echo "🎉 ModernBERT MoM setup complete!"
```

---

## 📊 資源使用預測

### 訓練階段
```
ModernBERT-base: 300 MB
LoRA (r=8): 需要額外 500 MB GPU 內存
Batch Size: 4-16 (取決於 GPU)
Total: ~800-1000 MB GPU 內存
```

### 推理階段 (MoM)
```
基礎模型: 300 MB (加載一次)
LoRA x 4: 6-7 MB × 4 = ~28 MB
Tokenizer: 共享
────────────────────
總計: ~328 MB (vs 4 個獨立模型 1.2 GB)
節省: ~900 MB ✅
```

---

## 🎓 何時考慮其他基礎模型

### 使用 ModernBERT-base ✅
- 英文應用為主
- 8K 上下文足夠
- 想要最新架構

### 使用 mmBERT-32K ⭐ (推薦)
- 需要長上下文 (32K)
- 多語言應用
- 最佳整體性能

### 使用 mmBERT-base
- 需要多語言 (1800+)
- 8K 上下文足夠
- 節省少量內存

### 使用 RoBERTa-base
- 英文應用
- 最佳英文性能
- 輕量級 (120 MB)

### 使用 BERT-base
- 邊緣設備
- 極限資源約束
- 需要 CPU 推理

---

## ✅ 檢查清單

- [ ] 所有 4 個模型都用 ModernBERT-base 訓練
- [ ] 配置文件更新為 `use_modernbert: true`
- [ ] 配置文件更新為 `use_mmbert_32k: false`
- [ ] 所有 model_id 指向 `modernbert_*` 模型
- [ ] 標籤映射文件都存在
- [ ] 驗證腳本通過 (6/6 checks)
- [ ] 部署測試成功

---

*文檔生成於: 2026-05-13*  
*備選方案: ModernBERT-base MoM*  
*推薦標準: mmBERT-32K MoM* ⭐
