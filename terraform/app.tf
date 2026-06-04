resource "tls_private_key" "app_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "app_cert" {
  private_key_pem = tls_private_key.app_key.private_key_pem

  subject {
    common_name  = var.domain_name
    organization = "Kubernetes Task Lab"
  }

  validity_period_hours = 8760 # 1 ano de validade

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret_v1" "app_tls_secret" {
  metadata {
    name      = "app-tls"
    namespace = "default"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.app_cert.cert_pem
    "tls.key" = tls_private_key.app_key.private_key_pem
  }
}

resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = "task-app"
    namespace = "default"
    labels = {
      app = "task-app"
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "task-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "task-app"
        }
      }

      spec {
        container {
          name  = "task-app"
          image = var.app_image
          
          image_pull_policy = "Always"

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          port {
            container_port = 8080
          }

          env {
            name  = "DB_HOST"
            value = "postgres"
          }

          env {
            name  = "DB_PORT"
            value = "5432"
          }

          env {
            name  = "DB_USER"
            value = var.db_user
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres_secret.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name  = "DB_NAME"
            value = var.db_name
          }

          # Probe de Liveness: O Kubelet reinicia o container se falhar consecutivamente
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          # Probe de Readiness: O K8s remove o pod do balanceamento de carga se falhar
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "app_service" {
  metadata {
    name      = "task-app"
    namespace = "default"
  }

  spec {
    selector = {
      app = "task-app"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "app_ingress" {
  depends_on = [helm_release.ingress_nginx]

  metadata {
    name      = "task-app-ingress"
    namespace = "default"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.domain_name]
      secret_name = kubernetes_secret_v1.app_tls_secret.metadata[0].name
    }

    rule {
      host = var.domain_name
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.app_service.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
