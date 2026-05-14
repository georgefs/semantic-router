# Category Signal Model Training Example

這個資料夾把 category signal model 的訓練例子整理成可直接參考的結構：

- `data/`：訓練資料範例
- `scripts/`：訓練啟動腳本
- `configs/`：runtime 設定檔範例
- `models/`：訓練後的模型輸出位置（首次執行時自動建立）

這裡的 category signal model 指的是用來做 domain / category classification 的模型。它會先把 query 分到 category，再把 category 送進 routing / decision flow。

## 目錄結構

```text
category-signal-model-training-example/
├── README.md
├── configs/
│   └── category-signal-model.yaml
├── data/
│   └── training-samples.jsonl
├── models/                          # 訓練輸出位置（自動建立）
│   └── qwen3_generative_classifier_r16/
│       ├── adapter_config.json
│       ├── adapter_model.bin       # LoRA 權重
│       ├── config.json
│       ├── label_mapping.json      # Category 映射表
│       ├── special_tokens_map.json
│       ├── tokenizer.json
│       ├── tokenizer_config.json
│       └── logs/                   # 訓練日誌
└── scripts/
    └── train_qwen3_generative_lora.sh
```

## 訓練流程

### 1. 訓練路線

repo 內推薦的訓練腳本是：

- [`src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py`](../../../../../src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py)

這是 generative LoRA 的訓練路線：

- **輸入**：一段 question
- **輸出**：模型直接生成 category name (如 "law", "computer science")
- **集成**：把生成的 category 送到 runtime 的 `classifier.category_model`

### 2. 訓練腳本

啟動腳本放在：

- [`scripts/train_qwen3_generative_lora.sh`](./scripts/train_qwen3_generative_lora.sh)

**執行訓練：**

```bash
# 使用默認參數（推薦）
bash scripts/train_qwen3_generative_lora.sh

# 自訂參數
EPOCHS=10 LORA_RANK=32 GPU_ID=0 bash scripts/train_qwen3_generative_lora.sh

# 自訂輸出位置
OUTPUT_DIR=/path/to/custom/model bash scripts/train_qwen3_generative_lora.sh
```

**可配置環境變數：**

- `EPOCHS`：訓練輪數（默認：8）
- `LORA_RANK`：LoRA rank（默認：16）
- `MAX_SAMPLES_PER_CATEGORY`：每個 category 最多樣本數（默認：150）
- `GPU_ID`：GPU 編號（默認：0）
- `OUTPUT_DIR`：模型輸出位置（默認：`./models/qwen3_generative_classifier_r16`）

### 3. 模型輸出位置

訓練完成後，模型會保存到：

```
./models/qwen3_generative_classifier_r16/
├── adapter_model.bin        # LoRA 權重（主要模型檔案）
├── label_mapping.json       # Category 對應表
├── tokenizer.json           # 分詞器
└── logs/                    # 訓練日誌
```

**重要檔案：**

- `adapter_model.bin`：LoRA 微調權重，需要與 Qwen3-0.6B 基礎模型搭配使用
- `label_mapping.json`：包含 category 映射、id2label、label2id 等信息
- `tokenizer.json`：與 Qwen3 相匹配的分詞器配置

## Runtime 設定

設定檔範例放在：

- [`configs/category-signal-model.yaml`](./configs/category-signal-model.yaml)

**重要配置項：**

```yaml
classifier:
  category_model:
    model_id: "qwen3_generative_classifier"
    model_path: "../models/qwen3_generative_classifier_r16"  # 訓練輸出的模型位置
    label_mapping_path: "../models/qwen3_generative_classifier_r16/label_mapping.json"
    threshold: 0.75
    fallback_category: "other"
```

**路徑說明：**

- `model_path`：指向訓練輸出的 LoRA 模型目錄
- `label_mapping_path`：指向 `label_mapping.json` 檔案

這些路徑是相對於配置檔所在的位置。

## 測試模型

訓練後，可以直接測試模型的推理效果（訓練腳本執行完會自動測試）。

如果需要單獨測試：

```bash
cd /path/to/repo
python src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py \
  --mode test \
  --model-path ./docs/agent/playbooks/category-signal-model-training-example/models/qwen3_generative_classifier_r16
```

## 訓練資料

訓練資料範例放在：

- [`data/training-samples.jsonl`](./data/training-samples.jsonl)

**格式：** JSONL，每行一個範例

```json
{"question":"What is the main purpose of photosynthesis in plants?","category":"biology"}
```

**包含 14 個 categories：**

biology, business, chemistry, computer science, economics, engineering, health, history, law, math, other, philosophy, physics, psychology

## 什麼時候重訓

你應該重訓 category model 的情況：

- 新增或刪除 category
- category 定義改了
- prompt distribution 明顯改變
- fallback 比例升高（表示分類準確率下降）
- category 跟 downstream routing 對不上

## 常見問題

### Q: 模型儲存在哪裡？
A: 預設儲存在 `./models/qwen3_generative_classifier_r16/`（相對於此資料夾）

### Q: 如何指定自訂的輸出位置？
A: 設定 `OUTPUT_DIR` 環境變數：
```bash
OUTPUT_DIR=/my/custom/path bash scripts/train_qwen3_generative_lora.sh
```

### Q: Runtime 如何載入訓練好的模型？
A: 透過 `configs/category-signal-model.yaml` 中的 `model_path` 和 `label_mapping_path` 配置

### Q: 訓練需要多久？
A: 約 5-15 分鐘（取決於 GPU 和樣本數）

## 簡短結論

這個資料夾把 category signal model 的最小可用範例切成四部分：

1. `data/` - 訓練樣本
2. `scripts/` - 訓練啟動腳本
3. `configs/` - Runtime 設定（指向訓練後的模型）
4. `models/` - 訓練輸出位置
