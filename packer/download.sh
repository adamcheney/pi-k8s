#!/bin/bash -e

cd "$(dirname "$0")/downloads"

ETCD_VERSION=3.3.13
KUBERNETES_VERSION=1.15.1
CNI_PLUGINS_VERSION=0.8.1

if [[ -f etcd && -f etcdctl ]]; then
    echo "etcd already downloaded"
else
    echo "Downloading etcd"

    wget -q https://github.com/etcd-io/etcd/releases/download/v$ETCD_VERSION/etcd-v$ETCD_VERSION-linux-arm64.tar.gz{,.asc}

    gpg --import ../keys/etcd.gpg
    gpg -v --verify etcd-v$ETCD_VERSION-linux-arm64.tar.gz{.asc,}

    tar --strip-components 1 -xzf etcd-v$ETCD_VERSION-linux-arm64.tar.gz etcd-v$ETCD_VERSION-linux-arm64/etcd{,ctl}

    rm etcd-v$ETCD_VERSION-linux-arm64.tar.gz{,.asc}
fi


kube_release_uri=https://storage.googleapis.com/kubernetes-release/release/v$KUBERNETES_VERSION/bin/linux/arm64/
bins=(
  kube-apiserver
  kube-controller-manager
  kube-proxy
  kube-scheduler
  kubectl
  kubelet
)

for bin in "${bins[@]}"; do
    if [ -f "$bin" ]; then
        echo "$bin already downloaded"
    else
        echo "Downloading $bin"

        wget -q "$kube_release_uri$bin"

        curl -sf "$kube_release_uri$bin.md5" | tr '\n' ' ' > "$bin.md5"
        echo " $bin" >> "$bin.md5"

        md5sum --check "$bin.md5"

        rm "$bin.md5"
    fi
done

if [ -d cni-plugins ]; then
  echo "cni plugins already downloaded"
else
  echo "Downloading cni plugins"
  wget -q https://github.com/containernetworking/plugins/releases/download/v$CNI_PLUGINS_VERSION/cni-plugins-linux-arm64-v$CNI_PLUGINS_VERSION.tgz
  mkdir cni-plugins
  tar -xzf cni-plugins-linux-arm64-v$CNI_PLUGINS_VERSION.tgz -C cni-plugins
  rm cni-plugins-linux-arm64-v$CNI_PLUGINS_VERSION.tgz
fi
