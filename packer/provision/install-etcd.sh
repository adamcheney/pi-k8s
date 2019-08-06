#!/bin/bash -e

echo "Installing etcd"

# Copy binaries
cp /tmp/downloads/etcd{,ctl} /usr/local/bin

# Create directories
mkdir -p \
    /var/lib/etcd \
    /etc/etcd

# Copy certificates
cp /tmp/generated/kubernetes.pem /etc/etcd/kubernetes.pem
cp /tmp/generated/kubernetes-key.pem /etc/etcd/kubernetes-key.pem
cp /tmp/generated/ca.pem /etc/etcd/ca.pem

cat > /etc/systemd/system/etcd.service <<EOM
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name $HOSTNAME \\
  --advertise-client-urls https://$HOSTNAME:2379 \\
  --listen-client-urls https://0.0.0.0:2379 \\
  --listen-peer-urls https://0.0.0.0:2380 \\
  --initial-advertise-peer-urls https://$HOSTNAME:2380 \\
  --initial-cluster $(echo "$PEER_HOSTNAMES" | sed 's/[^,]*/\0=https:\/\/\0:2380/g') \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --client-cert-auth \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
Environment=ETCD_UNSUPPORTED_ARCH=arm64
Type=notify

[Install]
WantedBy=multi-user.target
EOM

# Enable etcd at boot
systemctl daemon-reload
systemctl enable etcd.service
