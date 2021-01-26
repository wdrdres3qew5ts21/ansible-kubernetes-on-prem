#!/bin/bash
# ansible-kubernetes-on-prem
# please fil kubernetes control plane
KUBE_CONTROL_PLANE="depa1"

apt-get update -y

modprobe br_netfilter

echo 1 > /proc/sys/net/ipv4/ip_forward

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

apt-get install firewalld -y

## Master Node
firewall-cmd --add-port=6443/tcp --permanent

firewall-cmd --add-port=2370-2380/tcp --permanent

firewall-cmd --add-port=10250-10252/tcp --permanent

firewall-cmd --reload

## Worker Node
firewall-cmd --add-port=10250/tcp --permanent

firewall-cmd --add-port=30000-32767/tcp --permanent

swapoff --all

sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

export VERSION=1.18
export OS=xUbuntu_20.04
echo "$OS  $VERSION"

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | apt-key add -

apt-get update -y
apt-get install cri-o cri-o-runc -y


if [ "$HOSTNAME" = "$KUBE_CONTROL_PLANE" ]; then
    echo "=== Inittials Control Plane ==="
    sudo kubeadm init phase control-plane controller-manager
    sudo kubeadm init --control-plane-endpoint depa1.sit.kmutt.ac.th  --upload-cert
else
    echo "=== Join Worker Node to Control Plane ==="
fi

