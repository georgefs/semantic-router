# Playbooks Index

這裡是 `docs/agent/playbooks/` 的總索引。

## Model Overview

| Model | 主要用途 | 典型資料來源 | 訓練入口 | Runtime 入口 |
|---|---|---|---|---|
| Category | 把 query 分到 domain/category，再送進 routing decision | MMLU-Pro 類分類資料 | [`category-signal-model-training-example/README.md`](category-signal-model-training-example/README.md) | `classifier.category_model` |
| PII | 抽出敏感實體，供遮罩、阻擋、稽核 | Presidio + AI4Privacy | [`pii-model-training-example/README.md`](pii-model-training-example/README.md) | `classifier.pii_model` |
| Feedback | 判斷 follow-up 是否滿意、需澄清、答錯、要不同答案 | 多輪對話 / feedback datasets | [`feedback-model-training-example/README.md`](feedback-model-training-example/README.md) | `feedback_detector` |
| Jailbreak | 判斷 prompt 是否含繞過限制、注入、惡意意圖 | toxic-chat + Salad-Data | [`jailbreak-model-training-example/README.md`](jailbreak-model-training-example/README.md) | `prompt_guard` |

## How To Read This Table

- `Category` 是路由前的 domain classifier。
- `PII` 是安全與隱私抽取模型。
- `Feedback` 是使用者滿意度與回饋分類。
- `Jailbreak` 是 prompt 安全防線。

如果你是在找訓練範例，直接進對應的 `Training Example` 目錄就行。

## Training Examples

- [Feedback Model Training Example](feedback-model-training-example/README.md)
  - 4-class user feedback classifier 的訓練、資料與 runtime 設定範例
- [Jailbreak Model Training Example](jailbreak-model-training-example/README.md)
  - binary jailbreak / prompt-injection detector 的訓練、資料與 runtime 設定範例
- [Category Signal Model Training Example](category-signal-model-training-example/README.md)
  - category / domain classifier 的訓練、資料與 runtime 設定範例
- [PII Model Training Example](pii-model-training-example/README.md)
  - token classification PII detector 的訓練、資料與 runtime 設定範例

## Routing Playbooks

- [Go Router](go-router.md)
- [Model Selection Algorithms](model-selection-algorithms.md)
- [Custom Signal](custom-signal.md)
- [E2E Selection](e2e-selection.md)
- [vLLM SR CLI Docker](vllm-sr-cli-docker.md)

## How To Use This Index

先從這個索引頁找你要的主題，再進到對應 playbook。
如果你要的是訓練範例，就優先看 `Training Examples`。
