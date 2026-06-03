#!/bin/bash
set -euo pipefail

IMAGE_NAME="lednew245/k8s-task-app:latest"

echo "============================================="
echo "🚀 Iniciando Build e Push da Imagem Docker"
echo "============================================="

# 1. Executa o build utilizando o Dockerfile multi-stage na pasta app/
echo "📦 Buildando a imagem docker: $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" ./app

# 2. Envia a imagem para o Docker Hub do usuário
echo "📤 Realizando o push da imagem para o Docker Hub..."
echo "Nota: Certifique-se de estar logado usando 'docker login' antes de continuar."
docker push "$IMAGE_NAME"

echo "============================================="
echo "✅ Imagem enviada com sucesso para o Docker Hub!"
echo "============================================="
