# Jailbreak Model Training Example

這個資料夾把 jailbreak detector 的訓練例子整理成可直接參考的結構：

- `data/`：訓練資料範例
- `scripts/`：訓練啟動腳本
- `configs/`：runtime 設定檔範例

這裡的 jailbreak model 指的是 binary security classifier。它會判斷輸入是否屬於 jailbreak、prompt injection、繞過限制等惡意請求，供 `prompt_guard` 在 request pipeline 前段使用。

## 目錄內容

```text
jailbreak-model-training-example/
├── README.md
├── configs/
│   └── prompt-guard.yaml
├── data/
│   └── training-samples.jsonl
└── scripts/
    └── train_jailbreak_lora_cpu.sh
```

## 訓練路線

repo 內目前推薦的訓練腳本是：

- [`src/training/model_classifier/prompt_guard_fine_tuning_lora/jailbreak_bert_finetuning_lora.py`](../../../../../src/training/model_classifier/prompt_guard_fine_tuning_lora/jailbreak_bert_finetuning_lora.py)

這是一條 binary sequence classification 路線：

- 輸入一段 prompt
- 模型判斷是否 jailbreak
- runtime 再把結果接進 `prompt_guard`

## 這個模型學什麼

jailbreak detector 不是做一般內容分類，也不是做回饋理解。  
它是在學辨識：

- `safe`
- `jailbreak`

資料來源包含：

- `lmsys/toxic-chat`
- `OpenSafetyLab/Salad-Data`

腳本會自動平衡這兩種來源，並加入短 jailbreak patterns 強化泛化。

## 建議模型

這個訓練腳本支援：

- `mmbert-32k`
- `mmbert-base`
- `modernbert-base`
- `bert-base-uncased`
- `roberta-base`

如果你想要 CPU / baseline 穩定性，通常會先用：

- `bert-base-uncased`
- `roberta-base`

如果你要更強的多語言或長上下文能力，可以用：

- `mmbert-32k`

## Runtime 設定

jailbreak detector 在 runtime 中屬於 `prompt_guard`：

```yaml
prompt_guard:
  enabled: true
  model_id: "models/mom-jailbreak-classifier"
  threshold: 0.7
  use_cpu: true
  use_modernbert: false
  use_mmbert_32k: true
  jailbreak_mapping_path: "models/mom-jailbreak-classifier/jailbreak_type_mapping.json"
```

### 欄位說明

- `enabled`
  - 是否啟用 prompt guard
- `model_id`
  - 你訓練好的 jailbreak classifier 路徑或模型名
- `threshold`
  - confidence 門檻
- `use_cpu`
  - 是否強制用 CPU
- `use_modernbert`
  - 是否走 ModernBERT backend
- `use_mmbert_32k`
  - 是否走 mmBERT-32K backend
- `jailbreak_mapping_path`
  - label mapping 檔案

## 訓練資料

訓練資料範例放在：

- [`data/training-samples.jsonl`](./data/training-samples.jsonl)

每筆資料通常是：

- `text`
- `label`

其中 `label` 會是：

- `safe`
- `jailbreak`

## 訓練腳本

啟動腳本放在：

- [`scripts/train_jailbreak_lora_cpu.sh`](./scripts/train_jailbreak_lora_cpu.sh)

它提供一個可直接執行的 CPU wrapper。  
預設行為是：

- 使用 `bert-base-uncased`
- 啟用 LoRA
- 使用混合資料訓練

### 範例用法

```bash
./scripts/train_jailbreak_lora_cpu.sh
```

指定其他 backbone：

```bash
MODEL=roberta-base ./scripts/train_jailbreak_lora_cpu.sh
```

快速 smoke test：

```bash
QUICK=true ./scripts/train_jailbreak_lora_cpu.sh
```

## 什麼時候重訓

你應該重訓 jailbreak detector 的情況：

- 新的 jailbreak pattern 大量出現
- prompt injection 形式改變
- `safe` / `jailbreak` 分布變了
- false negative 上升
- runtime 的 confidence 門檻需要重新校準

## 簡短結論

這個資料夾把 jailbreak model 的最小可用範例切成三部分：

1. `data/` 放 binary security 样本
2. `scripts/` 放 CPU 版 LoRA 啟動方式
3. `configs/` 放 runtime `prompt_guard` 設定
