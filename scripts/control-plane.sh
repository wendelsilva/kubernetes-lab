#!/bin/bash
set -euo pipefail

ENV_FILE="/vagrant/.env"

IP_ADDR="192.168.56.10"
POD_CIDR="192.168.0.0/16"

echo "=== Carregando variáveis de ambiente ==="
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
else
    echo "ERRO: Arquivo $ENV_FILE não encontrado!" >&2
    exit 1
fi

echo "=== [1/3] Inicializando Control Plane com Kubeadm ==="
sudo kubeadm init --apiserver-advertise-address="$IP_ADDR" --pod-network-cidr="$POD_CIDR" --token="$STATIC_TOKEN"

echo "=== [2/3] Configurando Acesso ao Kubeconfig ==="
# CORREÇÃO: Cria a pasta e garante permissão RECURSIVA para o usuário vagrant
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

# Configura acesso para o usuário root (facilita troubleshooting)
mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config

# AJUSTE TERRAFORM: Cria a estrutura exata no host que o Terraform espera ler (../.kube/config)
mkdir -p /tmp/.kube
sudo cp /etc/kubernetes/admin.conf /tmp/.kube/config

mkdir -p /vagrant/.kube
cp /tmp/.kube/config /vagrant/.kube/config

rm -rf /tmp/.kube

sudo sed -i 's/127.0.0.1/192.168.56.10/g' /vagrant/.kube/config

echo "=== [3/3] Instalando Plugin de Rede Calico (CNI) ==="
# Calico exige o Tigera Operator e Custom Resources
sudo -u vagrant kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
sudo -u vagrant kubectl wait --for=condition=established --timeout=60s crd/installations.operator.tigera.io
sudo -u vagrant kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml

echo "=== Inicialização do Control Plane finalizada! ==="