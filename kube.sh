#!/bin/bash
# ansible-kubernetes-on-prem
# please fil kubernetes control plane
KUBE_CONTROL_PLANE="depa1"
export VERSION=1.20
export OS=xUbuntu_20.04

apt-get update -y

swapoff --all

echo 1 > /proc/sys/net/ipv4/ip_forward

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
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


echo "$OS  $VERSION"

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | apt-key add -

apt-get update -y
apt-get install cri-o cri-o-runc -y
cp 02-cgroup-manager.conf /etc/crio/crio.conf.d/

systemctl daemon-reload

systemctl restart cri-o


if [ "$HOSTNAME" = "$KUBE_CONTROL_PLANE" ]; then
    echo "=== Inittials Control Plane ==="
    sudo kubeadm init --control-plane-endpoint depa1.sit.kmutt.ac.th  --upload-certs
else
    echo "=== Join Worker Node to Control Plane ==="
fi

