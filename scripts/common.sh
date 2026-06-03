#!/bin/bash
set -euo pipefail

K8S_VERSION="v1.36"

# Garante que o APT não abra telas interativas solicitando entrada do usuário
export DEBIAN_FRONTEND=noninteractive

echo "=== [1/5] Desabilitando SWAP ==="
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

echo "=== [2/5] Carregando Módulos de Kernel Necessários ==="
sudo mkdir -p /etc/modules-load.d
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "=== [3/5] Configurando Parâmetros de Sysctl de Rede ==="
sudo mkdir -p /etc/sysctl.d
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo "=== [4/5] Instalando e Configurando Container Runtime (Containerd) ==="
sudo apt-get update -y
sudo apt-get install -y containerd

sudo mkdir -p /etc/containerd
# Correção importante: Garante que o dump do containerd seja salvo corretamente com privilégios elevados
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

echo "=== [5/5] Instalando Kubeadm, Kubelet e Kubectl (Kubernetes v1.29) ==="
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p -m 755 /etc/apt/keyrings

# Correção importante: O curl envia os dados para o gpg, e o gpg precisa usar sudo para escrever na pasta restrita
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "=== Preparação do nó concluída com sucesso! ==="