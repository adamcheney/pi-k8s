#!/bin/bash -e


cp /tmp/downloads/kube-apiserver /usr/local/bin/kube-apiserver
cp /tmp/downloads/kube-controller-manager /usr/local/bin/kube-controller-manager
cp /tmp/downloads/kube-scheduler /usr/local/bin/kube-scheduler
cp /tmp/downloads/kubectl /usr/local/bin/kubectl


chmod +x /usr/local/bin/kube-apiserver
chmod +x /usr/local/bin/kube-controller-manager
chmod +x /usr/local/bin/kube-scheduler
chmod +x /usr/local/bin/kubectl


mkdir -p /var/lib/kubernetes/ /etc/kubernetes/config


cp \
    /tmp/generated/ca.pem \
    /tmp/generated/ca-key.pem \
    /tmp/generated/kubernetes-key.pem \
    /tmp/generated/kubernetes.pem \
    /tmp/generated/service-account-key.pem \
    /tmp/generated/service-account.pem \
    /var/lib/kubernetes/


cat > /var/lib/kubernetes/encryption-config.yaml <<EOM
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: $(cat /tmp/generated/encryption.key)
      - identity: {}
EOM


kubectl config set-cluster kubernetes \
--certificate-authority=/var/lib/kubernetes/ca.pem \
--embed-certs=true \
--server=https://127.0.0.1:6443 \
--kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
--client-certificate=/tmp/generated/kube-controller-manager.pem \
--client-key=/tmp/generated/kube-controller-manager-key.pem \
--embed-certs=true \
--kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig

kubectl config set-context default \
--cluster=kubernetes \
--user=system:kube-controller-manager \
--kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig


kubectl config set-cluster kubernetes \
--certificate-authority=/var/lib/kubernetes/ca.pem \
--embed-certs=true \
--server=https://127.0.0.1:6443 \
--kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
--client-certificate=/tmp/generated/kube-scheduler.pem \
--client-key=/tmp/generated/kube-scheduler-key.pem \
--embed-certs=true \
--kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig

kubectl config set-context default \
--cluster=kubernetes \
--user=system:kube-scheduler \
--kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig


cat > /etc/kubernetes/config/kube-scheduler.yaml <<EOM
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOM

cat > /etc/systemd/system/kube-apiserver.service <<EOM
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --apiserver-count=1 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=$(echo "$PEER_HOSTNAMES" | sed 's/[^,]*/https:\/\/\0:2379/g') \\
  --event-ttl=1h \\
  --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOM


cat > /etc/systemd/system/kube-controller-manager.service <<EOM
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \
  --address=0.0.0.0 \
  --cluster-cidr=10.200.0.0/16 \
  --cluster-name=kubernetes \
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \
  --leader-elect=true \
  --root-ca-file=/var/lib/kubernetes/ca.pem \
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --use-service-account-credentials=true \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOM


cat > /etc/systemd/system/kube-scheduler.service <<EOM
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \
  --config=/etc/kubernetes/config/kube-scheduler.yaml \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOM


systemctl daemon-reload
systemctl enable kube-apiserver kube-controller-manager kube-scheduler
systemctl start kube-apiserver kube-controller-manager kube-scheduler
