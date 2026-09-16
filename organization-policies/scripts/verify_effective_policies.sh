#!/usr/bin/env bash
# 對 policies_catalog.yaml 收錄的「每一條」政策（不分 category / enabled / type，
# 包含 Terraform 完全不碰的 unverified 項目）呼叫
#   gcloud org-policies describe constraints/<id> --organization=ORG_ID --effective
# 檢查實際生效狀態。這是唯讀查詢，不需要事先知道 constraint 是 boolean 還是
# list —— API 回應本身會用 booleanPolicy / listPolicy 這兩種 key 標明型態，
# 所以即使是 schema 未核對過的 unverified 項目，也能得到真實現況，而不是
# 假設「Google 說自動強制＝一定有生效」。
#
# 用法: ./scripts/verify_effective_policies.sh ORG_ID
set -euo pipefail

ORG_ID="${1:?用法: $0 ORG_ID}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATALOG="${SCRIPT_DIR}/../policies_catalog.yaml"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "錯誤：找不到 gcloud，請先安裝並執行 gcloud auth login。" >&2
  exit 1
fi

HAVE_JQ=0
if command -v jq >/dev/null 2>&1; then
  HAVE_JQ=1
fi

# 不依賴 yq/python-yaml：catalog 裡每條政策的 id 都是固定格式的
# "  - id: xxx.yyy" 一行，直接用 grep/sed 取出即可，避免額外相依套件。
# 用 while read 迴圈組陣列而非 mapfile：macOS 內建 /bin/bash 是 3.2（Apple
# 因 GPLv3 授權問題不升級），沒有 mapfile（bash 4+ 才有），mapfile 會直接
# 造成腳本在 macOS 上執行失敗。
IDS=()
while IFS= read -r line; do
  IDS+=("$line")
done < <(grep -E '^[[:space:]]*- id:' "$CATALOG" | sed -E 's/^[[:space:]]*- id:[[:space:]]*//')

TOTAL=${#IDS[@]}
printf "共 %d 條政策，逐一查詢 organizations/%s 的實際生效狀態...\n\n" "$TOTAL" "$ORG_ID"
printf "%-55s %-10s %s\n" "CONSTRAINT" "狀態" "細節"
printf '%.0s-' {1..100}; echo

RESTRICTED=0
UNRESTRICTED=0
NOT_FOUND=0
ERROR=0

for id in "${IDS[@]}"; do
  RESPONSE=$(gcloud org-policies describe "constraints/${id}" \
    --organization="${ORG_ID}" --effective --format=json 2>/tmp/verify_policy_err.txt) \
    && RC=0 || RC=$?

  if [ "$RC" -ne 0 ]; then
    if grep -qi "not found\|NOT_FOUND" /tmp/verify_policy_err.txt; then
      printf "%-55s %-10s %s\n" "$id" "未設定" "(無 effective policy，可能沿用系統預設)"
      NOT_FOUND=$((NOT_FOUND + 1))
    else
      printf "%-55s %-10s %s\n" "$id" "查詢失敗" "$(head -n1 /tmp/verify_policy_err.txt)"
      ERROR=$((ERROR + 1))
    fi
    continue
  fi

  if [ "$HAVE_JQ" -eq 1 ]; then
    # 注意：不能用 `.booleanPolicy.enforced // empty`——jq 的 `//` 會把 JSON
    # false 當成「沒有值」（跟 null 同樣視為 falsy），導致 enforced=false
    # （明確關閉）被誤判成「沒有 booleanPolicy」而落入下面的 list 判斷分支，
    # 反而被算成「已限制」，恰好跟這個腳本要偵測的 drift 方向相反。改用
    # `has("enforced")` 明確判斷欄位是否存在，再取值。
    BOOL_ENFORCED=$(echo "$RESPONSE" | jq -r 'if (.booleanPolicy // {}) | has("enforced") then .booleanPolicy.enforced | tostring else empty end')
    LIST_ALL=$(echo "$RESPONSE" | jq -r '.listPolicy.allValues // empty')
    LIST_ALLOWED=$(echo "$RESPONSE" | jq -c '.listPolicy.allowedValues // empty')
    LIST_DENIED=$(echo "$RESPONSE" | jq -c '.listPolicy.deniedValues // empty')

    if [ -n "$BOOL_ENFORCED" ]; then
      if [ "$BOOL_ENFORCED" = "true" ]; then
        printf "%-55s %-10s %s\n" "$id" "已限制" "booleanPolicy.enforced=true"
        RESTRICTED=$((RESTRICTED + 1))
      else
        printf "%-55s %-10s %s\n" "$id" "未限制" "booleanPolicy.enforced=false"
        UNRESTRICTED=$((UNRESTRICTED + 1))
      fi
    elif [ -n "$LIST_ALL" ]; then
      printf "%-55s %-10s %s\n" "$id" "list" "allValues=${LIST_ALL}"
      RESTRICTED=$((RESTRICTED + 1))
    elif [ "$LIST_ALLOWED" != "empty" ] || [ "$LIST_DENIED" != "empty" ]; then
      printf "%-55s %-10s %s\n" "$id" "list" "allowed=${LIST_ALLOWED} denied=${LIST_DENIED}"
      RESTRICTED=$((RESTRICTED + 1))
    else
      printf "%-55s %-10s %s\n" "$id" "未知格式" "$(echo "$RESPONSE" | tr -d '\n' | cut -c1-60)"
      ERROR=$((ERROR + 1))
    fi
  else
    printf "%-55s %-10s %s\n" "$id" "raw" "$(echo "$RESPONSE" | tr -d '\n' | cut -c1-60)"
  fi
done

echo
echo "彙總：已限制/生效 ${RESTRICTED}，未限制 ${UNRESTRICTED}，無 effective policy ${NOT_FOUND}，查詢異常 ${ERROR}（共 ${TOTAL} 條）"
[ "$HAVE_JQ" -eq 1 ] || echo "備註：未安裝 jq，僅印出原始 JSON，未自動判讀狀態。"
echo
echo "注意：對於新一代 managed constraint（id 含 .managed. 的項目），"
echo "此指令是否能正確回傳其 effective 狀態尚未完全驗證過，若持續顯示"
echo "「未設定」，請改用 Console → Organization Policies 頁面人工核對。"

rm -f /tmp/verify_policy_err.txt
