#!/bin/bash -e

cd "$(dirname "$0")"

gen_kubelet_cert() {
    if [ -z "$HOSTNAME" ]; then
        cat > "$HOSTNAME-csr.json" <<EOM
{
  "CN": "system:node:$HOSTNAME",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "O": "system:nodes"
    }
  ]
}
EOM

    cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -hostname=$HOSTNAME \
        -profile=kubernetes \
        $HOSTNAME-csr.json | cfssljson -bare $HOSTNAME
fi
}

if [ -f generated/ca.pem ]; then
    echo "packer/generated/ca.pem exists, skipping file generation"
    exit 0

    cd generated
    gen_kubelet_cert
fi

mkdir -p generated

cp templates/*.json generated

cd generated

# Generate certs
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    admin-csr.json | cfssljson -bare admin

cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kube-proxy-csr.json | cfssljson -bare kube-proxy

cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kube-scheduler-csr.json | cfssljson -bare kube-scheduler

cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    service-account-csr.json | cfssljson -bare service-account

cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=master0,master1,master2,127.0.0.1,kubernetes.default \
    -profile=kubernetes \
    kubernetes-csr.json | cfssljson -bare kubernetes

gen_kubelet_cert()

# SSH key
ssh-keygen -t rsa -N "" -f id_rsa

# Kubernetes encryption at rest
head -c 32 /dev/urandom | base64 > encryption.key
