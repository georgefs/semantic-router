# 支持的基礎模型完整指南

## 🎯 當前官方支持的基礎模型

根據訓練腳本中的 `choices` 定義，以下模型被官方支持：

### 📋 完整對比表

| 模型 | 大小 | 上下文 | 特點 | 推薦度 | 備註 |
|------|------|--------|------|--------|------|
| **mmBERT-32K** | 309 MB | 32K tokens | 多語言，扩展上下文 | ⭐⭐⭐⭐⭐ | **官方推薦** |
| **mmBERT-base** | ~300 MB | 8K tokens | 多語言，1800+語言 | ⭐⭐⭐⭐ | 好的平衡 |
| **ModernBERT-base** | ~300 MB | 8K tokens | 最新架構 | ⭐⭐⭐ | 實驗性 |
| **BERT-base-uncased** | ~110 MB | 512 tokens | 輕量，穩定 | ⭐⭐⭐ | CPU友好 |
| **RoBERTa-base** | ~120 MB | 512 tokens | 最佳性能 | ⭐⭐⭐⭐ | 性能最好 |

---

## 🚀 詳細說明

### 1️⃣ **mmBERT-32K** ⭐⭐⭐⭐⭐（官方推薦）

```
模型ID: llm-semantic-router/mmbert-32k-yarn

特性:
  • 大小: 309 MB
  • 上下文: 32K tokens (YaRN extended)
  • 語言: 多語言 (500+ 語言)
  • 架構: ModernBERT
  • LoRA 支持: ✅ 優化

優勢:
  ✅ 最長的上下文窗口 (32K vs 8K/512)
  ✅ 多語言支持最好
  ✅ YaRN 上下文擴展技術
  ✅ 官方推薦，MoM 標準
  ✅ 推理速度快

缺點:
  ❌ 模型稍大
  
適用場景:
  • 長文本分類
  • 多語言應用
  • 需要大上下文的任務
  • 生產部署 (推薦)

使用:
  use_mmbert_32k: true

訓練命令:
  python train.py --model mmbert-32k --epochs 8
```

---

### 2️⃣ **mmBERT-base** ⭐⭐⭐⭐

```
模型ID: 內置別名 "mmbert-base"

特性:
  • 大小: ~300 MB
  • 上下文: 8K tokens
  • 語言: 超多語言 (1800+ 語言)
  • 架構: 多語言 ModernBERT
  
優勢:
  ✅ 超強多語言支持
  ✅ 文件大小較小
  ✅ 8K 上下文足夠大多數任務
  ✅ 訓練速度快

缺點:
  ❌ 上下文不如 32K 版本
  
適用場景:
  • 多語言分類
  • 不需要超長上下文的任務
  • 資源受限環境

使用:
  use_mmbert_32k: false
  use_modernbert: true

訓練命令:
  python train.py --model mmbert-base --epochs 8
```

---

### 3️⃣ **ModernBERT-base** ⭐⭐⭐

```
模型ID: 內置別名 "modernbert-base"

特性:
  • 大小: ~300 MB
  • 上下文: 8K tokens
  • 語言: 英文主要
  • 架構: 最新 ModernBERT
  
優勢:
  ✅ 最新架構（更好的效率）
  ✅ 文件大小小
  ✅ 推理速度快
  ✅ 訓練速度快

缺點:
  ❌ 多語言支持不如 mmBERT
  ❌ 相對較新，穩定性不如舊版本
  
適用場景:
  • 實驗項目
  • 英文為主的應用
  • 追求最新技術的開發者

使用:
  use_modernbert: true
  use_mmbert_32k: false

訓練命令:
  python train.py --model modernbert-base --epochs 8
```

---

### 4️⃣ **BERT-base-uncased** ⭐⭐⭐

```
模型ID: huggingface/bert-base-uncased

特性:
  • 大小: 110 MB (最小)
  • 上下文: 512 tokens (最小)
  • 語言: 英文
  • 架構: 經典 BERT
  
優勢:
  ✅ 最輕量 (110 MB)
  ✅ 最穩定（經過驗證）
  ✅ CPU 友好
  ✅ 訓練最快
  ✅ 推理延遲最低
  ✅ 很多工具支持

缺點:
  ❌ 上下文最短 (512 tokens)
  ❌ 性能不如新模型
  ❌ 無多語言支持
  
適用場景:
  • 邊緣設備
  • 受限資源環境
  • 快速原型開發
  • 學習和實驗

使用:
  (默認或無特殊標志)

訓練命令:
  python train.py --model bert-base-uncased --epochs 8
```

---

### 5️⃣ **RoBERTa-base** ⭐⭐⭐⭐

```
模型ID: huggingface/roberta-base

特性:
  • 大小: 120 MB
  • 上下文: 512 tokens
  • 語言: 英文
  • 架構: 改進的 BERT
  
優勢:
  ✅ 性能最好 (vs BERT-base)
  ✅ 輕量級 (120 MB)
  ✅ 訓練速度快
  ✅ 穩定且可靠
  ✅ 很多應用場景已驗證

缺點:
  ❌ 上下文仍只有 512 tokens
  ❌ 無多語言支持
  
適用場景:
  • 單語言應用 (英文)
  • 性能需求高
  • 資源有限但不是極端受限
  • 經過驗證的生產環境

使用:
  (默認或無特殊標志)

訓練命令:
  python train.py --model roberta-base --epochs 8
```

---

## 📊 性能對比

### 推理速度
```
最快: BERT-base < RoBERTa < ModernBERT-base < mmBERT-base ≤ mmBERT-32K
差異: BERT 作為基線 (1x)
      RoBERTa 約 0.95x (稍快)
      ModernBERT 約 1.1x (稍慢)
      mmBERT 約 1.2-1.5x (考慮上下文)
```

### 精度
```
最佳: RoBERTa > ModernBERT-base ≈ mmBERT-base ≈ mmBERT-32K > BERT-base
差異: 在標準基準上，新模型比 BERT 好 2-5%
```

### 上下文支持
```
512 tokens:     BERT-base, RoBERTa-base
8K tokens:      mmBERT-base, ModernBERT-base
32K tokens:     mmBERT-32K ⭐
```

### 多語言
```
英文主要:       BERT-base, RoBERTa-base
多語言:         mmBERT-base (1800+), ModernBERT-base
超多語言:       mmBERT-32K (500+) ✅
```

---

## 🎯 選擇指南

### 🔴 如果你想要...

**最佳整體性能和功能**
→ **mmBERT-32K** ⭐⭐⭐⭐⭐
- 長上下文 ✅
- 多語言 ✅
- 快速推理 ✅
- 官方推薦 ✅

**最佳多語言支持**
→ **mmBERT-base** ⭐⭐⭐⭐
- 1800+ 語言 ✅
- 文件小 ✅
- 8K 上下文 ✅

**最佳英文性能**
→ **RoBERTa-base** ⭐⭐⭐⭐
- 性能最佳 (BERT 之後) ✅
- 輕量 ✅
- 訓練快 ✅

**最輕量選項**
→ **BERT-base-uncased** ⭐⭐⭐
- 110 MB ✅
- CPU 友好 ✅
- 最穩定 ✅

**實驗/最新技術**
→ **ModernBERT-base** ⭐⭐⭐
- 最新架構 ✅
- 快速推理 ✅
- 尚未廣泛驗證 ⚠️

---

## ⚠️ 官方遷移路徑

### 原本支持
```
BERT-base-uncased (經典)
RoBERTa-base (改進)
```

### 過渡期
```
ModernBERT-base (新架構)
```

### 現在推薦
```
mmBERT-32K (官方標準) ⭐
mmBERT-base (多語言)
```

### 已廢棄
```
Qwen3 (過時，不使用 MoM)
```

---

## 🔧 訓練命令示例

### 使用 mmBERT-32K（推薦）
```bash
# Category Signal Model
python train_category_classifier.py --model mmbert-32k --epochs 8 --lora-rank 16

# Jailbreak Detector
python jailbreak_bert_finetuning_lora.py --model mmbert-32k --epochs 8

# PII Detector
python pii_bert_finetuning_lora.py --model mmbert-32k --epochs 8

# Feedback Detector
python train_feedback_detector.py --model mmbert-32k --epochs 8
```

### 使用其他模型
```bash
# RoBERTa（單語言英文，最佳性能）
python jailbreak_bert_finetuning_lora.py --model roberta-base --epochs 8

# BERT-base（輕量 CPU）
python jailbreak_bert_finetuning_lora.py --model bert-base-uncased --epochs 8

# mmBERT-base（多語言）
python jailbreak_bert_finetuning_lora.py --model mmbert-base --epochs 8

# ModernBERT-base（實驗）
python jailbreak_bert_finetuning_lora.py --model modernbert-base --epochs 8
```

---

## 📝 配置設置

### mmBERT-32K（推薦）
```yaml
classifier:
  category_model:
    model_id: "mmbert32k_category_classifier"
    use_mmbert_32k: true      # ← MoM 標准
    use_cpu: true

prompt_guard:
  model_id: "models/mmbert32k-jailbreak-detector"
  use_mmbert_32k: true
```

### 其他模型
```yaml
# 如果使用 RoBERTa 或其他
classifier:
  category_model:
    model_id: "roberta_category_classifier"
    use_mmbert_32k: false
    use_cpu: true
```

---

## ✅ 推薦方案

### 生產環境（推薦）
```
Base Model: mmBERT-32K
Architecture: MoM (Mixture of Models)
LoRA Rank: 16
Batch Size: 16-32
Training Epochs: 8+
```

### 快速開發
```
Base Model: BERT-base-uncased
Architecture: 獨立
LoRA Rank: 8
Batch Size: 4-8
Training Epochs: 1-2
```

### 多語言應用
```
Base Model: mmBERT-base
Architecture: MoM-like
LoRA Rank: 16
Batch Size: 16
Training Epochs: 8+
```

### 邊緣設備
```
Base Model: BERT-base-uncased
Architecture: 獨立
LoRA Rank: 8
Batch Size: 1-2
Training Epochs: 4-8
Quantization: 8-bit
```

---

## 📌 總結

| 用途 | 推薦模型 | 原因 |
|------|---------|------|
| 生產標準 | mmBERT-32K | 最佳平衡，官方標準 |
| 多語言 | mmBERT-base | 1800+ 語言支持 |
| 最佳性能 | RoBERTa-base | 英文場景最好 |
| 最輕量 | BERT-base | 110 MB，CPU 友好 |
| 實驗探索 | ModernBERT-base | 最新技術 |

---

*文檔生成於: 2026-05-13*  
*當前標準: mmBERT-32K (MoM 架構)*  
*所有 4 個模型已配置為 mmBERT-32K ✅*
