#!/bin/bash
# =========================================================
# 腳本名稱：Nping 網路品質自動化分析報告 (V5.1 顯示優化版)
# 邏輯核心：
#   1. 中途掉包 -> 判定為【確認掉包】
#   2. 結尾掉包 -> 判定為【未定狀態】(Last Sentinel)
#   3. 顯示優化 -> 延遲標題自動轉換為 ms 單位
# =========================================================

# ---------------------------------------------------------
# [參數設定區]
# ---------------------------------------------------------
LOG="ping_intgpn.log"       # Log 檔案名稱
LATENCY_THRESHOLD=0.2       # 卡頓判定閥值 (單位: 秒)，預設 0.2 (=200ms)

if [ ! -f "$LOG" ]; then
    echo "錯誤: 找不到 $LOG 檔案。"
    exit 1
fi

echo "=========================================="
echo "    8 小時網路品質結案報告 (V5.1 最終版)"
echo "=========================================="

# ---------------------------------------------------------
# [核心] 時間基準校正
# ---------------------------------------------------------
START_TIME_STR=$(grep "Starting Nping" "$LOG" | sed 's/.*at //')

if [ -z "$START_TIME_STR" ]; then
    FILE_MOD_EPOCH=$(stat -c %Y "$LOG")
    LAST_REL_SEC=$(tac "$LOG" | grep -m 1 -E "SENT|RCVD" | awk -F'[()s]' '{print $2}' | cut -d. -f1)
    BASE_EPOCH=$((FILE_MOD_EPOCH - LAST_REL_SEC))
else
    BASE_EPOCH=$(date -d "$START_TIME_STR" +%s)
fi

HUMAN_START_TIME=$(date -d @"$BASE_EPOCH" '+%Y-%m-%d %H:%M:%S')
echo "測試啟動時間: $HUMAN_START_TIME"
echo "------------------------------------------"

# ---------------------------------------------------------
# [1] 總量統計
# ---------------------------------------------------------
S=$(grep -c "SENT" "$LOG")
R=$(grep -c "RCVD" "$LOG")
L=$((S-R))
if [ $S -eq 0 ]; then echo "尚未有數據"; exit 1; fi
RATE=$(awk "BEGIN {printf \"%.2f\", ($L/$S)*100}")
echo "[1] 封包掉包率: $RATE % (Sent: $S, Rcvd: $R, Lost: $L)"

# ---------------------------------------------------------
# [2] 延遲分佈
# ---------------------------------------------------------
echo "[2] 延遲分佈 (RTT Distribution):"
awk -F'[()s]' '/SENT/ {s=$2} /RCVD/ {
    rtt=$2-s;
    if(rtt < 0.01) a++;        else if(rtt < 0.05) b++;
    else if(rtt < 0.1) c++;    else if(rtt < 0.2) d++;
    else if(rtt < 0.3) e++;    else if(rtt < 0.5) f++;
    else g++;
} END {
    printf "    < 10ms      %d 次\n", a;
    printf "    10-50ms     %d 次\n", b;
    printf "    50-100ms    %d 次\n", c;
    printf "    100-200ms   %d 次\n", d;
    printf "    200-300ms   %d 次\n", e;
    printf "    300-500ms   %d 次\n", f;
    printf "    > 500ms     %d 次\n", g;
}' "$LOG"

# ---------------------------------------------------------
# [3] 掉包精確定位 (邊界控制邏輯)
# ---------------------------------------------------------
echo "[3] 掉包事件定位:"

PYTHON_SCRIPT="/tmp/find_loss_v5.py"
cat <<EOF > "$PYTHON_SCRIPT"
import sys
from datetime import datetime, timedelta

log_file = "$LOG"
base_epoch = $BASE_EPOCH

# 1. 建立水位與最後一筆 SENT 的位置
balance = 0
history = []
last_sent_line = 0

try:
    with open(log_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            if "SENT" in line:
                balance += 1
                last_sent_line = line_num
                history.append({'type': 'SENT', 'line': line_num, 'content': line.strip(), 'bal': balance})
            elif "RCVD" in line:
                balance -= 1
                history.append({'type': 'RCVD', 'line': line_num, 'content': line.strip(), 'bal': balance})

    final_balance = balance
    total_packets = len(history)

    if final_balance <= 0:
        print("    結果: 完整無掉包 (或水位異常為負)。")
    else:
        found_real_drop = False

        # 遍歷每一個「階梯」
        for target_level in range(final_balance):

            # 找出最後一次水位等於 target_level 的索引
            last_index = -1
            for i, record in enumerate(history):
                if record['bal'] == target_level:
                    last_index = i

            # 掉包發生在該位置之後的第一個 SENT
            if last_index != -1 and last_index + 1 < len(history):
                lost_pkt = None
                for k in range(last_index + 1, len(history)):
                    if history[k]['type'] == 'SENT':
                        lost_pkt = history[k]
                        break

                if lost_pkt:
                    is_last_sent = (lost_pkt['line'] == last_sent_line)

                    if not is_last_sent:
                        found_real_drop = True
                        try:
                            rel_sec_str = lost_pkt['content'].split('(')[1].split('s')[0]
                            rel_sec = float(rel_sec_str)
                            real_time = datetime.fromtimestamp(base_epoch) + timedelta(seconds=rel_sec)
                            time_str = real_time.strftime('%Y-%m-%d %H:%M:%S')

                            print(f"    🔴 確認掉包！")
                            print(f"    - 真實時間: {time_str}")
                            print(f"    - 相對時間: {rel_sec}s")
                            print(f"    - Log 行號: {lost_pkt['line']}")
                            print(f"    - 原始內容: {lost_pkt['content']}")
                        except:
                            print(f"    🔴 確認掉包 (解析失敗) - 行號 {lost_pkt['line']}")
                    else:
                        print(f"    ⚪ 未定狀態 (Inconclusive): 測試終止邊界")
                        print(f"       - 說明: 此為最後一筆發送紀錄，無法驗證程式是否提前結束。")
                        print(f"       - Log 行號: {lost_pkt['line']}")

        if not found_real_drop:
             print("    (無確認的中途掉包，剩餘未回封包均位於測試邊界)")

except Exception as e:
    print(f"Python 分析錯誤: {e}")
EOF

python3 "$PYTHON_SCRIPT"
rm -f "$PYTHON_SCRIPT"

# ---------------------------------------------------------
# [4] 持續性卡頓分析 (Top 10)
# ---------------------------------------------------------

# 自動將閥值轉換為 ms 單位以利顯示
THRESHOLD_MS=$(awk "BEGIN {print $LATENCY_THRESHOLD * 1000}")

echo "[4] 持續性卡頓事件 Top 10 (RTT > ${THRESHOLD_MS}ms):"

awk -v limit="$LATENCY_THRESHOLD" -F'[()s]' '/SENT/ {s=$2} /RCVD/ {
    rtt=$2-s;
    if(rtt > limit) {
        count++;
        if(count == 1) start_sec = int($2);
    } else {
        if(count > 0) print count, start_sec;
        count = 0;
    }
} END {
    if(count > 0) print count, start_sec;
}' "$LOG" | sort -rn | head -n 10 | while read duration start_rel; do
    REAL_EPOCH=$((BASE_EPOCH + start_rel))
    REAL_TIME_STR=$(date -d @"$REAL_EPOCH" '+%Y-%m-%d %H:%M:%S')
    echo "    持續 $duration 秒 | 起始: $REAL_TIME_STR (相對: ${start_rel}s)"
done

echo "=========================================="