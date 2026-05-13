# Category Signal Model Training Example

這個資料夾把 category signal model 的訓練例子整理成可直接參考的結構：

- `data/`：訓練資料範例
- `scripts/`：訓練啟動腳本
- `configs/`：runtime 設定檔範例

這裡的 category signal model 指的是用來做 domain / category classification 的模型。它會先把 query 分到 category，再把 category 送進 routing / decision flow。

## 目錄內容

```text
category-signal-model-training-example/
├── README.md
├── configs/
│   └── category-signal-model.yaml
├── data/
│   └── training-samples.jsonl
└── scripts/
    └── train_qwen3_generative_lora.sh
```

## 訓練路線

repo 內目前推薦的訓練腳本是：

- [`src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py`](../../../../../src/training/model_classifier/classifier_model_fine_tuning_lora/ft_qwen3_generative_lora.py)

這是一條 generative LoRA 的訓練路線：

- 輸入一段 question
- 模型直接生成 category name
- 再把 category name 接到 runtime 的 `classifier.category_model`

## Runtime 設定

設定檔範例放在：

- [`configs/category-signal-model.yaml`](./configs/category-signal-model.yaml)

它示範兩件事：

1. `classifier.category_model` 的基本設定
2. `categories` 如何把 category 映射到 downstream routing

## 訓練資料

訓練資料範例放在：

- [`data/training-samples.jsonl`](./data/training-samples.jsonl)

每筆資料會是 `question + category` 的 JSONL 格式。

## 訓練腳本

啟動腳本放在：

- [`scripts/train_qwen3_generative_lora.sh`](./scripts/train_qwen3_generative_lora.sh)

它只是包一層方便你固定常用參數，真正的訓練入口仍然是 repo 內的 Python script。

## 什麼時候重訓

你應該重訓 category model 的情況：

- 新增或刪除 category
- category 定義改了
- prompt distribution 明顯改變
- fallback 比例升高
- category 跟 downstream routing 對不上

## 簡短結論

這個資料夾把 category signal model 的最小可用範例切成三部分：

1. `data/` 放訓練樣本
2. `scripts/` 放訓練啟動方式
3. `configs/` 放 runtime 設定
