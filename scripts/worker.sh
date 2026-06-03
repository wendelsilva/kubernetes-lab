#!/bin/bash
set -euo pipefail

ENV_FILE="/vagrant/.env"

CONTROL_PLANE_ADDR="192.168.56.10:6443"

echo "=== Carregando variáveis de ambiente ==="
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
else
    echo "ERRO: Arquivo $ENV_FILE não encontrado!" >&2
    exit 1
fi

echo "=== [1/2] Aguardando pelo comando de Join do Control Plane ==="

echo "=== [2/2] Executando ingresso no cluster Kubernetes ==="
# Executa o join usando o token estático e ignorando a checagem de hash do CA
sudo kubeadm join "$CONTROL_PLANE_ADDR" --token "$STATIC_TOKEN" --discovery-token-unsafe-skip-ca-verification

echo "=== Nó Worker integrado ao cluster com sucesso! ==="