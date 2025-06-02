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

function snooze {
    sleep $1
}

echo nameserver 1.1.1.1 > /etc/resolv.conf
echo nameserver 8.8.8.8 >> /etc/resolv.conf

ifname=$(basename $(ls -1 /etc/wireguard/*.conf | head -1) .conf)
export TARGET_ADDRESS=10.1.1.1

while true
do
  curl -s --proxy socks5://127.0.0.1:1080 http://${TARGET_ADDRESS} --max-time 1 > /dev/null
  if [ $? -eq 0 ]; then
    # echo "VPN health"
    if [ -n "$UPTIME_PUSH_URL" ]; then
      curl -s -o /dev/null "$UPTIME_PUSH_URL"
    fi
    snooze 300 &
    wait $!
  else
    # echo "VPN not health"
    wg-quick down /etc/wireguard/$ifname.conf 2>/dev/null
    if ! ping -c 1 ${TARGET_ADDRESS} >/dev/null 2>&1 && ping -c 1 1.1.1.1 >/dev/null 2>&1; then
      # echo "Not at home, but have internet"
      wg-quick up /etc/wireguard/$ifname.conf 2>/dev/null
      # sed -i'' -e "s/__replace_me_ifname__/$ifname/" /etc/sockd.conf
      sed -i "s/^external: * .*/external: $ifname/" /etc/sockd.conf
      snooze 3 &
      wait $!
      kill -SIGTERM `pgrep sockd` 2>/dev/null
      /usr/sbin/sockd &
    else
      if ping -c 1 ${TARGET_ADDRESS} >/dev/null; then
        # echo "At home"
        sed -i "s/^external: * .*/external: eth0/" /etc/sockd.conf
        kill -SIGTERM `pgrep sockd` 2>/dev/null
        /usr/sbin/sockd &
      fi
    fi
    snooze 60 &
    wait $!
  fi
done
