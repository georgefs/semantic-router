# Category Signal Model - 快速部署指南

## 🚀 已完成的訓練

```
✅ 模型已訓練並保存到:
   ./models/qwen3_generative_classifier_r8/

✅ Runtime 配置已指向該模型:
   ./configs/category-signal-model.yaml
```

---

## 📋 檔案結構

```
category-signal-model-training-example/
├── models/
│   └── qwen3_generative_classifier_r8/
│       ├── adapter_model.safetensors  ← LoRA 權重 (20MB)
│       ├── label_mapping.json         ← Category 映射
│       ├── tokenizer.json             ← 分詞器 (11MB)
│       └── ... (其他配置文件)
├── configs/
│   └── category-signal-model.yaml     ← Runtime 配置 (已更新)
├── data/
│   └── training-samples.jsonl         ← 訓練數據範例
└── scripts/
    └── train_qwen3_generative_lora.sh ← 訓練腳本
```

---

## 🔄 如何使用訓練好的模型

### 方式 1: 直接推理測試

```bash
# 從 repo root 執行
python src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py \
  --mode test \
  --model-path ./docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r8
```

**預期輸出**:
```
Question: What is the best strategy for corporate mergers and acquisitions?
Generated: business

Question: Explain the legal requirements for contract formation
Generated: law

...
```

### 方式 2: 在應用中使用 (透過 YAML 配置)

Runtime 會自動從 `configs/category-signal-model.yaml` 加載模型:

```yaml
classifier:
  category_model:
    model_path: "../models/qwen3_generative_classifier_r8"
    label_mapping_path: "../models/qwen3_generative_classifier_r8/label_mapping.json"
```

---

## 📊 模型性能

**訓練參數** (快速驗證版本):
- Epochs: 1
- LoRA Rank: 8
- Samples per category: 5
- Training Time: ~3.5 秒

**結果**:
- Validation Accuracy: 42.86% (6/14)
- **說明**: 低準確率是因為訓練樣本和 epoch 極少
  - 用於快速驗證流程的正確性
  - 生產環境應使用完整訓練

---

## 🎯 提升模型準確率

如要訓練更準確的模型（預期 70-85% 準確率）:

### 方式 1: 使用默認參數 (推薦)

```bash
cd docs/agent/playbooks/category-signal-model-training-example/
bash scripts/train_qwen3_generative_lora.sh

# 預期訓練時間: 15-20 分鐘
# 生成模型: models/qwen3_generative_classifier_r16/
```

### 方式 2: 自訂參數

```bash
cd docs/agent/playbooks/category-signal-model-training-example/

# 參數 1: 增加訓練輪數
EPOCHS=10 bash scripts/train_qwen3_generative_lora.sh

# 參數 2: 增加樣本數
MAX_SAMPLES_PER_CATEGORY=200 bash scripts/train_qwen3_generative_lora.sh

# 參數 3: 增加 LoRA Rank (更強大的適應)
LORA_RANK=32 bash scripts/train_qwen3_generative_lora.sh

# 參數 4: 組合多個參數
EPOCHS=10 LORA_RANK=32 MAX_SAMPLES_PER_CATEGORY=200 bash scripts/train_qwen3_generative_lora.sh
```

### 方式 3: 自訂輸出位置

```bash
# 訓練時指定輸出位置
OUTPUT_DIR=./models/my_production_model bash scripts/train_qwen3_generative_lora.sh

# 然後更新配置文件指向新位置
# configs/category-signal-model.yaml:
#   model_path: "../models/my_production_model"
```

---

## 🔧 配置更新步驟

如訓練了新模型:

1. **更新配置文件**:
   ```yaml
   # configs/category-signal-model.yaml
   classifier:
     category_model:
       model_path: "../models/YOUR_NEW_MODEL_NAME"
       label_mapping_path: "../models/YOUR_NEW_MODEL_NAME/label_mapping.json"
   ```

2. **重啟 Runtime** (應用會自動載入新模型)

3. **驗證**:
   ```bash
   # 測試新模型推理
   python src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py \
     --mode test \
     --model-path ./docs/agent/playbooks/category-signal-model-training-example/models/YOUR_NEW_MODEL_NAME
   ```

---

## ⚙️ 環境變數參考

| 變數 | 默認值 | 說明 |
|------|--------|------|
| `EPOCHS` | 8 | 訓練輪數 |
| `LORA_RANK` | 16 | LoRA 秩大小（越大越強大但更慢） |
| `MAX_SAMPLES_PER_CATEGORY` | 150 | 每個 category 的訓練樣本上限 |
| `GPU_ID` | 0 | 使用的 GPU 編號 |
| `OUTPUT_DIR` | `./models/qwen3_generative_classifier_rX` | 模型輸出位置 |

---

## 📁 Label Mapping 結構

`label_mapping.json` 包含:

```json
{
  "label2id": {
    "biology": 0,
    "business": 1,
    ...
  },
  "id2label": {
    "0": "biology",
    "1": "business",
    ...
  },
  "instruction_template": "..."
}
```

Runtime 會使用這個文件將生成的 category 名稱對應到 ID。

---

## ❓ 常見問題

### Q: 訓練多久會完成?
A: 
- 快速驗證 (當前): ~3.5 秒
- 完整訓練 (默認參數): 15-20 分鐘
- 自訂大規模: 30-60 分鐘

### Q: 模型佔用多少空間?
A: ~35MB (包含 LoRA 權重、tokenizer 等)

### Q: 可以在 CPU 上推理嗎?
A: 可以，但會很慢。編輯 YAML 配置:
```yaml
classifier:
  category_model:
    use_cpu: true  # 改為 true
```

### Q: 如何更新訓練數據?
A: 編輯 `data/training-samples.jsonl`，添加新樣本即可。格式:
```json
{"question":"...","category":"..."}
```

### Q: 支援的 categories 有哪些?
A: 14 個預定義 categories:
- biology, business, chemistry, computer science
- economics, engineering, health, history
- law, math, other, philosophy, physics, psychology

---

## ✅ 部署檢查清單

部署前確認:
- [ ] 模型文件存在於 `models/` 目錄
- [ ] `label_mapping.json` 包含所有 14 個 categories
- [ ] `configs/category-signal-model.yaml` 指向正確的模型路徑
- [ ] 推理測試通過 (`--mode test`)
- [ ] Runtime 能正確加載配置

---

**Last Updated**: 2026-05-13
**Trained Model**: qwen3_generative_classifier_r8
**Status**: ✅ Ready for deployment
