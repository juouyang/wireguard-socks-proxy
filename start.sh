#!/bin/sh

# exec docker run \
#     --rm --tty --interactive \
#     --name=wireguard-socks-proxy \
#     --cap-add=NET_ADMIN \
#     --publish 127.0.0.1:1080:1080 \
#     --volume "$(realpath "$1"):/etc/wireguard/:ro" \
#     kizzx2/wireguard-socks-proxy

docker stop wireguard
docker rm wireguard
exec docker run -d --privileged --name=wireguard \
    --restart unless-stopped \
    --cap-add=NET_ADMIN \
    --volume "$(realpath "$1"):/etc/wireguard/:ro" \
    --health-cmd='ping 10.1.1.1 -c 3 -W 3 > /dev/null || exit -1' \
    --health-timeout=10s \
    --health-retries=3 \
    --health-interval=30s \
    --label autoheal=false \
    --publish 127.0.0.1:31080:1080 juouyang/wireguard-socks-proxy:1.0.2-arm64
