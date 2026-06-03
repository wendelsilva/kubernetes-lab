terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.1.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.3.0"
    }
  }
}

# Configura o provider do Kubernetes apontando para o kubeconfig gerado pelo Vagrant
provider "kubernetes" {
  config_path = "${path.module}/../.kube/config"
}

# Configura o provider do Helm compartilhando as mesmas credenciais do Kubernetes
provider "helm" {
  kubernetes = {
    config_path = "${path.module}/../.kube/config"
  }
}

# Instalação do NGINX Ingress Controller via Helm
# Configurado corretamente com os blocos 'set' embutidos no recurso
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  # Muda de LoadBalancer para NodePort para rodar no ambiente local do Libvirt
  # Mapeia as portas diretamente no host para simplificar o roteamento local
  set = [
    {
      name  = "controller.service.type"
      value = "NodePort"
    },
    {
      name  = "controller.hostPort.enabled"
      value = "true"
    }
  ]

  # Margem de tempo confortável para baixar a imagem sem estourar timeout
  timeout = 600
}