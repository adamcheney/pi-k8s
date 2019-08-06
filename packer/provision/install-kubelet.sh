#!/bin/bash -e

apt-get -y install \
  conntrack \
  ipset \
  socat \
  containerd \
  runc
#   docker.io

mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes \
  /etc/containerd

wget -q --show-progress --https-only --timestamping \
  https://github.com/containernetworking/plugins/releases/download/v0.8.1/cni-plugins-linux-arm64-v0.8.1.tgz \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/arm64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/arm64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/arm64/kubelet


chmod +x kubectl kube-proxy kubelet
mv kubectl kube-proxy kubelet runc runsc /usr/local/bin/
tar -xvf cni-plugins-linux-arm64-v0.8.1.tgz -C /opt/cni/bin/
rm cni-plugins-linux-arm64-v0.8.1.tgz



# Get the IP of eth0
primary_ip="$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')"

# Last octet of primary IP
last_octet="$(echo "$primary_ip" | cut -d . -f 4)"

# Should not conflict, as long as node IP doesn't change
pod_cidr="10.200.$last_octet.0/24"

cat > /etc/cni/net.d/10-bridge.conf <<EOM
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "$pod_cidr"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOM

cat > /etc/cni/net.d/99-loopback.conf <<EOM
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOM

cat > /etc/containerd/config.toml << EOM
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "$(which runc)"
      runtime_root = ""
EOM

systemctl restart containerd

master0
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

INTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].networkIP)')

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
done