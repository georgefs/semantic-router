# 簡單測試 router 的狀況
curl -i -X POST http://127.0.0.1:11180/api/v1/eval \
      -H 'Content-Type: application/json' \
      -d '{"messages":[{"role":"user","content":"hello"}],"options":{"evaluate_all_signals":true,"trace":true}}'
