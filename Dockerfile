# Expose a WireGuard connection as SOCKS5 proxy
#
# Usage:
# 1. start.sh /path/to/your/wireguard/conf
# 2. SOCKS5 proxy will be available at 1080
#
# `start.sh` is a one line script, feel free to tweak it e.g. the port mapping

FROM alpine

RUN apk add --update-cache dante-server wireguard-tools openresolv ip6tables curl \
  && rm -rf /var/cache/apk/*

COPY ./sockd.conf /etc/
COPY ./entrypoint.sh /entrypoint.sh

HEALTHCHECK CMD ping 10.1.1.1 -c 3 -W 3 > /dev/null || exit 1

STOPSIGNAL SIGTERM

ENTRYPOINT "/entrypoint.sh"
