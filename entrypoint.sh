#!/bin/sh

# 設置信號處理函數
sigterm_handler() {
  # 在這裡執行接收到 SIGTERM 信號時要執行的操作
  echo "Received SIGTERM. Cleaning up..."
  # 清理任務
  # ...
  kill -SIGTERM `pgrep sockd`       2>/dev/null
  kill -SIGTERM `pgrep sleep`       2>/dev/null

  # 結束腳本
  exit 0
}

# 設置 SIGTERM 信號處理器
trap 'sigterm_handler' SIGTERM

set -e

function snooze {
    sleep $1
}

ifname=$(basename $(ls -1 /etc/wireguard/*.conf | head -1) .conf)
wg-quick up /etc/wireguard/$ifname.conf 2>/dev/null
sed -i'' -e "s/__replace_me_ifname__/$ifname/" /etc/sockd.conf

snooze 3 &
wait $!
/usr/sbin/sockd &
wait $!
