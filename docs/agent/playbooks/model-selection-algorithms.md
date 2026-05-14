# Model Selection Algorithms

這份文件整理 `semantic-router` 裡的 model selection algorithms：

- 它們各自看哪些參數
- 它們怎麼被建立或訓練
- 哪些是離線訓練模型，哪些是 runtime state

這裡的 `model selection` 指的是：

1. `decision` 先選出一組 `modelRefs`
2. selector 再在這組候選模型裡挑一個

也就是說，`decision` 負責「走哪條路」，`selection algorithm` 負責「在這條路上選哪台模型」。

## Selection Context

router 會先把 request 與 decision 相關資訊整理成 `SelectionContext`，再交給 selector。

常見欄位：

- `Query`
- `QueryEmbedding`
- `DecisionName`
- `CategoryName`
- `CandidateModels`
- `CandidateIterations`
- `CostWeight`
- `QualityWeight`
- `LatencyAwareTPOTPercentile`
- `LatencyAwareTTFTPercentile`
- `UserID`
- `SessionID`
- `ConversationHistory`
- `CacheAffinityCtx`

## Algorithm Summary

| Algorithm | 主要依據 | 是否訓練 | 訓練型態 |
|---|---|---:|---|
| `static` | `DecisionName` + 靜態分數 | 否 | 只讀 config |
| `elo` | Elo rating + `DecisionName` + `CostWeight` | 否 | runtime feedback 更新 |
| `router_dc` | `QueryEmbedding` + model embedding | 否 | runtime 初始化 embedding / feedback state |
| `automix` | quality / cost / verification / escalation value | 否 | runtime state 更新 |
| `hybrid` | 混合 `elo` / `router_dc` / `automix` / cost / cache affinity | 否 | 依賴 component selector |
| `latency_aware` | TPOT / TTFT percentile | 否 | 讀 latency stats |
| `rl_driven` | user / session / exploration / reward state | 否 | runtime online learning |
| `gmtrouter` | user graph / interaction history | 否 | runtime personalization state |
| `knn` | `QueryEmbedding` + `CategoryName` + training records | 是 | Python 離線訓練 |
| `kmeans` | `QueryEmbedding` + `CategoryName` + cluster model | 是 | Python 離線訓練 |
| `svm` | `QueryEmbedding` + `CategoryName` + decision boundary | 是 | Python 離線訓練 |
| `mlp` | `QueryEmbedding` + `CategoryName` + neural classifier | 是 | Python 離線訓練 |

## 1. `static`

### 用到的參數

- `DecisionName`
- `categories[].modelScores`
- `UseFirstCandidate`

### 怎麼選

`StaticSelector` 會讀 decision 對應的 category score，選最高分的 model。若沒有可用分數，會回退到第一個 candidate。

### 怎麼訓練

- 不訓練
- 只從 config 載入

### 適合情況

- 你只想要可預期、固定的模型映射
- 你不需要動態選模

## 2. `elo`

### 用到的參數

- `InitialRating`
- `KFactor`
- `CategoryWeighted`
- `DecayFactor`
- `MinComparisons`
- `CostScalingFactor`
- `StoragePath`
- `AutoSaveInterval`
- runtime 的 `DecisionName`
- runtime 的 `CostWeight`

### 怎麼選

Elo rating 會先轉成機率分布，再從候選模型中選分數最高者。  
如果開了 cost scaling，就會把成本因素加進去。

### 怎麼訓練

- 不是離線 batch training
- 主要靠 `UpdateFeedback()` 根據使用者回饋更新 rating
- 如果有 `StoragePath`，rating 可以持久化並 autosave

### 適合情況

- 你有持續累積的 preference / feedback
- 你想要一個可逐步演進的 ranking system

## 3. `router_dc`

### 用到的參數

- `Temperature`
- `DimensionSize`
- `MinSimilarity`
- `UseQueryContrastive`
- `UseModelContrastive`
- `RequireDescriptions`
- `UseCapabilities`
- runtime 的 `QueryEmbedding`
- runtime 的 `Query`

### 怎麼選

用 query embedding 跟 model embedding 做 similarity matching，找最相似的 model。  
如果 similarity 低於門檻，就 fallback。

### 怎麼訓練

- runtime 初始化時，會根據 model descriptions 建立 model embeddings
- feedback 會更新 query-model affinity state
- 本身不是 Go 內 batch training

### 適合情況

- 你相信 query semantics 可以直接對上 model capability
- 你有比較穩定的 model description / embedding pipeline

## 4. `automix`

### 用到的參數

- `VerificationThreshold`
- `MaxEscalations`
- `CostAwareRouting`
- `CostQualityTradeoff`
- `DiscountFactor`
- `UseLogprobVerification`
- model capability state：
  - `Cost`
  - `AvgQuality`
  - `VerificationProb`
  - `EscalationReward`

### 怎麼選

會算 expected value。  
如果啟用 cost-aware routing，會把 cost penalty 納入；否則偏向 quality。

### 怎麼訓練

- runtime 根據 feedback 更新 capability state
- 不是獨立離線訓練

### 適合情況

- 你想做成本 / 品質 / 驗證之間的折衷
- 你希望先用便宜模型，再視情況升級

## 5. `hybrid`

### 用到的參數

- `EloWeight`
- `RouterDCWeight`
- `AutoMixWeight`
- `CostWeight`
- `QualityGapThreshold`
- `NormalizeScores`
- `CacheAffinityCtx`

### 怎麼選

把 `elo`、`router_dc`、`automix` 的分數加權混合，再加上 cost 和 cache affinity 修正。

### 怎麼訓練

- 自己不獨立訓練
- 依賴 component selectors 的 state 與 feedback

### 適合情況

- 你不想把策略壓在單一 selector 上
- 你想讓不同訊號互補

## 6. `latency_aware`

### 用到的參數

- `LatencyAwareTPOTPercentile`
- `LatencyAwareTTFTPercentile`

### 怎麼選

看每個 model 的 TPOT / TTFT percentile，選延遲更低的候選。

### 怎麼訓練

- 不訓練
- 直接讀 latency stats

### 適合情況

- 你最在意延遲
- 你已經有可靠的 latency 指標

## 7. `rl_driven`

### 用到的參數

- `EnableLLMRouting`
- `LLMRoutingFallback`
- `UseThompsonSampling`
- `CostAwareness`
- `CostWeight`
- `SessionContextWeight`
- runtime 的 `UserID`
- runtime 的 `SessionID`
- runtime 的 `DecisionName`

### 怎麼選

可以走 Router-R1 LLM routing。  
否則會用 Thompson Sampling 或 epsilon-greedy 來選 model。

### 怎麼訓練

- 透過 feedback 更新 preference / belief state
- 屬於 online learning

### 適合情況

- 你想做 user personalization
- 你想讓 selection policy 隨互動演進

## 8. `gmtrouter`

### 用到的參數

- `EnablePersonalization`
- `MinInteractionsForPersonalization`
- `MaxInteractionsPerUser`
- `NumGNNLayers`
- runtime 的 `UserID`
- runtime 的 `SessionID`

### 怎麼選

- 互動數夠多時，走 personalized selection
- cold start 時，走預設 model score

### 怎麼訓練

- runtime 透過 feedback / interaction graph 更新 user state
- 不走離線 batch train

### 適合情況

- 你要 session-aware 或 user-aware routing
- 你有足夠互動資料可以累積偏好

## 9. `knn`

### 用到的參數

- `k`
- `QueryEmbedding`
- `CategoryName`

### 怎麼選

把 query embedding + category one-hot 做 KNN，找最近鄰後做 quality-weighted voting。

### 怎麼訓練

離線 Python 訓練：

- 輸入：`query embedding + category one-hot`
- label：`model_name`
- 權重：`quality` + `latency`

訓練結果會存成 JSON，runtime 再載入。

### 適合情況

- 類似 query 通常有類似最佳模型
- 你想要簡單、可解釋的近鄰方法

## 10. `kmeans`

### 用到的參數

- `NumClusters`
- `EfficiencyWeight`
- `QueryEmbedding`
- `CategoryName`

### 怎麼選

先把 feature vector 分群，再對 cluster 指派 model。

### 怎麼訓練

離線 Python 訓練：

- 用 feature vector 跑 KMeans
- 每個 cluster 再根據 quality + efficiency 選最佳 model

### 適合情況

- 你想把 query 空間分成幾個穩定區域
- 你希望比純 KNN 更便宜一些

## 11. `svm`

### 用到的參數

- `Kernel`
- `Gamma`
- `QueryEmbedding`
- `CategoryName`

### 怎麼選

用 SVM decision boundary 做分類，輸出最適合的 model。

### 怎麼訓練

離線 Python 訓練：

- 特徵同樣是 `query embedding + category one-hot`
- 預設 `rbf` kernel
- 會使用 quality / latency 相關的樣本權重或過濾

### 適合情況

- 你想要有明確 decision boundary 的分類器
- query space 有非線性結構

## 12. `mlp`

### 用到的參數

- `hidden_sizes`
- `learning_rate`
- `epochs`
- `dropout`
- `device`
- `QueryEmbedding`
- `CategoryName`

### 怎麼選

MLP 會把 feature vector 分到某個 model class。  
runtime 會先預測 model name，再去當前 decision 的 `modelRefs` 裡找對應候選。

### 怎麼訓練

離線 Python + PyTorch 訓練：

- input：`embedding + category one-hot`
- label：`model_name`
- loss：`CrossEntropyLoss`
- sample weight：`0.9 * quality + 0.1 * speed_factor`
- 有 early stopping

訓練完成後會輸出 JSON，runtime 用 Candle 載入。

### 注意事項

- `mlp` 不是 per-decision 訓練
- 它學的是一個共用的 model name space
- 如果 decision 的 `modelRefs` 換成沒見過的模型，可能會 fallback 或失配

### 適合情況

- 你要更強的非線性分類能力
- 你的 model universe 相對穩定

## 這份 repo 裡最重要的限制

對 `knn / kmeans / svm / mlp` 這些 ML selector 來說：

- 訓練是全域的，不是每個 decision 一份
- runtime 是在當前 `decision.ModelRefs` 裡做匹配
- 所以 `decision` 改掉候選模型集合時，要考慮模型名稱是否還在訓練語料內

## 建議的使用方式

- `static`：最簡單，適合固定映射
- `elo`：有 feedback 時很好用
- `router_dc`：想用 query semantics 選模
- `automix`：想顧 cost / quality / escalation
- `hybrid`：想把多種訊號混起來
- `latency_aware`：延遲優先
- `knn / kmeans / svm / mlp`：想做真正的離線 ML 選模

## 相關程式碼

- [Selection context](../../../src/semantic-router/pkg/selection/selector.go)
- [Selection factory](../../../src/semantic-router/pkg/selection/factory.go)
- [ML adapter](../../../src/semantic-router/pkg/selection/ml_adapter.go)
- [Decision evaluation](../../../src/semantic-router/pkg/extproc/req_filter_classification_runtime.go)
- [ML training pipeline](../../../src/training/model_selection/ml_model_selection/train.py)
- [ML models](../../../src/training/model_selection/ml_model_selection/models.py)
