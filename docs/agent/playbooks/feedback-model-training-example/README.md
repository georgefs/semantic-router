# Feedback Model Training Example

這個資料夾把 feedback detector 的訓練例子整理成可直接參考的結構：

- `data/`：訓練資料範例
- `scripts/`：訓練啟動腳本
- `configs/`：runtime 設定檔範例

這裡的 feedback model 指的是 4 類 user feedback classifier。它用 follow-up message 判斷使用者的回饋型態，供後續 routing、reward、或模型偏好調整使用。

## 目錄內容

```text
feedback-model-training-example/
├── README.md
├── configs/
│   └── feedback-model.yaml
├── data/
│   └── training-samples.jsonl
└── scripts/
    └── train_feedback_detector_lora.sh
```

## 訓練路線

repo 內目前推薦的訓練腳本是：

- [`src/training/model_classifier/user_feedback_classifier/train_feedback_detector.py`](../../../../../src/training/model_classifier/user_feedback_classifier/train_feedback_detector.py)

這是一條 4-class sequence classification 路線：

- 輸入一段 follow-up message
- 模型輸出回饋類別
- 再透過 runtime 的 `feedback_detector` 使用

## 這個模型學什麼

feedback detector 不是做安全檢查，也不是做 routing 內容分類。  
它是在學：

- `SAT`
- `NEED_CLARIFICATION`
- `WRONG_ANSWER`
- `WANT_DIFFERENT`

也就是使用者對上一輪回答的回饋型態。

## 資料來源與標註方式

repo 內的資料流程會從多個對話資料集整理 follow-up message，然後映射成 4 類標籤。

常見來源包含：

- MIMICS / MIMICS-Duo
- INSCIT
- MultiWOZ
- SGD
- ReDial
- Hazumi

實作上，訓練腳本支援：

- Hugging Face dataset ID
- 本地 JSONL 資料目錄

如果舊資料缺少 `SAT` 類，腳本會自動補 synthetic `SAT` 樣本。

## 建議模型

這個訓練腳本預設使用：

- `llm-semantic-router/mmbert-32k-yarn`

你也可以用 LoRA 方式訓練：

- `--use_lora`
- `--lora_rank`
- `--lora_alpha`
- `--merge_lora`

## Runtime 設定

feedback detector 在 runtime 中是 top-level 的：

```yaml
feedback_detector:
  enabled: true
  model_id: "models/mmbert32k_feedback_detector"
  threshold: 0.7
  use_cpu: true
  use_mmbert_32k: true
```

### 欄位說明

- `enabled`
  - 是否啟用 feedback detector
- `model_id`
  - 你訓練好的模型路徑或模型名
- `threshold`
  - confidence 門檻
- `use_cpu`
  - 是否強制用 CPU
- `use_mmbert_32k`
  - 是否走 mmBERT-32K backend

## 訓練資料

訓練資料範例放在：

- [`data/training-samples.jsonl`](./data/training-samples.jsonl)

每筆資料通常是：

- `text`
- `label`

其中 `label` 會對應到：

- `SAT`
- `NEED_CLARIFICATION`
- `WRONG_ANSWER`
- `WANT_DIFFERENT`

## 訓練腳本

啟動腳本放在：

- [`scripts/train_feedback_detector_lora.sh`](./scripts/train_feedback_detector_lora.sh)

它提供一個可直接執行的 LoRA 訓練 wrapper。  
預設行為是：

- 使用 mmBERT-32K YaRN
- 啟用 LoRA
- 使用 `feedback-detector-dataset`

### 範例用法

```bash
./scripts/train_feedback_detector_lora.sh
```

指定本地資料來源：

```bash
DATA_SOURCE=./data ./scripts/train_feedback_detector_lora.sh
```

切回 full fine-tune：

```bash
USE_LORA=false ./scripts/train_feedback_detector_lora.sh
```

## 什麼時候重訓

你應該重訓 feedback detector 的情況：

- feedback 標籤定義改了
- 資料來源換了
- follow-up message 分布改變
- 模型對 `WRONG_ANSWER` / `NEED_CLARIFICATION` 的辨識變差
- runtime 的 confidence 門檻需要重新校準

## 簡短結論

這個資料夾把 feedback model 的最小可用範例切成三部分：

1. `data/` 放 4-class feedback 樣本
2. `scripts/` 放 LoRA 訓練啟動方式
3. `configs/` 放 runtime `feedback_detector` 設定
