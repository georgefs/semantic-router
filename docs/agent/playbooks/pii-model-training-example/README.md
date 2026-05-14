# PII Model Training Example

這個資料夾把 PII model 的訓練例子整理成可直接參考的結構：

- `data/`：訓練資料範例
- `scripts/`：訓練啟動腳本
- `configs/`：runtime 設定檔範例

這裡的 PII model 指的是 token classification 的 PII detector。它會輸出像 `EMAIL`、`PHONE_NUMBER`、`SSN`、`LOCATION` 這類實體類型，供 runtime 做遮罩、阻擋或稽核。

## 目錄內容

```text
pii-model-training-example/
├── README.md
├── configs/
│   └── pii-model.yaml
├── data/
│   └── training-samples.jsonl
└── scripts/
    └── train_pii_lora_cpu.sh
```

## 訓練路線

repo 內目前推薦的訓練腳本是：

- [`src/training/model_classifier/pii_model_fine_tuning_lora/pii_bert_finetuning_lora.py`](../../../../../src/training/model_classifier/pii_model_fine_tuning_lora/pii_bert_finetuning_lora.py)

這是一條 LoRA token classification 路線：

- 輸入一段文字
- 用 token-level BIO 標註做訓練
- 模型輸出 PII entity type
- 再透過 `classifier.pii_model` 與 `pii_mapping_path` 接到 runtime

## 這個模型學什麼

PII model 不是做 route selection，而是做 token-level 內容抽取。  
它會把文字中的敏感片段標成 entity，例如：

- `EMAIL`
- `PHONE_NUMBER`
- `SSN`
- `CREDIT_CARD`
- `PERSON`
- `LOCATION`

runtime 會拿這些結果去做：

- 遮罩
- 阻擋
- 稽核
- 傳遞給後續 policy / cache 邏輯

## 資料來源與混合方式

repo 內的訓練腳本支援兩種資料來源：

- `Presidio` 研究資料
- `AI4Privacy` 資料集

預設會混合兩者：

- `AI4Privacy` 提供更大量、更多語言、更多變形
- `Presidio` 提供較穩定的 entity 標註

如果要看實際訓練參數，對應腳本支援：

- `--model`
- `--epochs`
- `--lora-rank`
- `--lora-alpha`
- `--lora-dropout`
- `--batch-size`
- `--learning-rate`
- `--max-samples`
- `--use-ai4privacy`
- `--no-ai4privacy`

## 建議模型

這個訓練腳本支援多個 backbone：

- `mmbert-32k`
- `mmbert-base`
- `modernbert-base`
- `bert-base-uncased`
- `roberta-base`

如果你想要較穩定且容易在 CPU 上跑，通常會從 `bert-base-uncased` 或 `roberta-base` 開始。

如果你想要較大的上下文與更強的多語言覆蓋，則會優先考慮 `mmbert-32k`。

## Runtime 設定

設定檔範例放在：

- [`configs/pii-model.yaml`](./configs/pii-model.yaml)

它示範 `classifier.pii_model` 的基本設定：

- `model_id`
- `threshold`
- `use_cpu`
- `use_mmbert_32k`
- `pii_mapping_path`

## 訓練資料

訓練資料範例放在：

- [`data/training-samples.jsonl`](./data/training-samples.jsonl)

每筆資料會是：

- `full_text`
- `spans`

其中 `spans` 內含：

- `start_position`
- `end_position`
- `entity_type`

這個資料格式對應到訓練腳本裡的 raw data 轉換流程，也就是先把 span 轉成 BIO labels，再 tokenization / alignment。

## 訓練腳本

啟動腳本放在：

- [`scripts/train_pii_lora_cpu.sh`](./scripts/train_pii_lora_cpu.sh)

它只是包一層方便你固定常用參數，真正的訓練入口仍然是 repo 內的 Python script。
預設行為是：

- 使用 `mmbert-32k`
- 開啟 AI4Privacy + Presidio 混合訓練
- 使用較小 batch size，適合 CPU 或單卡低記憶體環境

### 範例用法

```bash
./scripts/train_pii_lora_cpu.sh
```

切回 Presidio-only：

```bash
USE_AI4PRIVACY=false ./scripts/train_pii_lora_cpu.sh
```

指定其他 backbone：

```bash
MODEL=roberta-base ./scripts/train_pii_lora_cpu.sh
```

## 什麼時候重訓

你應該重訓 PII model 的情況：

- 新增或刪除 PII entity type
- 標註規則改了
- 來源資料分布明顯改變
- false positive / false negative 變多
- runtime 的 `pii_mapping_path` 或 label space 改了

## 簡短結論

這個資料夾把 PII model 的最小可用範例切成三部分：

1. `data/` 放 token classification 訓練樣本
2. `scripts/` 放 CPU 版 LoRA 啟動方式
3. `configs/` 放 runtime PII classifier 設定
