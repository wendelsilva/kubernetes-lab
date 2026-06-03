# 1. Secret para armazenar a senha do banco de dados
resource "kubernetes_secret_v1" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = "default"
  }

  data = {
    password = var.db_password
  }

  type = "Opaque"
}

# 2. Persistent Volume (PV) do tipo HostPath
resource "kubernetes_persistent_volume_v1" "postgres_pv" {
  metadata {
    name = "postgres-pv"
  }

  spec {
    capacity = {
      storage = "1Gi"
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "manual"
    
    # Define o volume persistido na VM do worker node
    persistent_volume_source {
      host_path {
        path = "/mnt/data/postgres"
        type = "DirectoryOrCreate"
      }
    }
  }
}

# 3. Persistent Volume Claim (PVC) associado ao PV
resource "kubernetes_persistent_volume_claim_v1" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = "default"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "manual"
    volume_name        = kubernetes_persistent_volume_v1.postgres_pv.metadata[0].name

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

# 4. Deployment do PostgreSQL v15
resource "kubernetes_deployment_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "default"
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        # Garante que o banco sempre rode no worker-1 para reutilizar o HostPath local
        node_selector = {
          "kubernetes.io/hostname" = "worker-1"
        }

        # Solução DevOps para corrigir permissões do diretório hostPath antes do banco iniciar
        init_container {
          name  = "fix-permissions"
          image = "busybox"
          command = ["sh", "-c", "chown -R 999:999 /var/lib/postgresql/data"]

          security_context {
            run_as_user = 0 # Roda como root temporariamente para alterar o dono da pasta
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        container {
          name  = "postgres"
          image = "postgres:15-alpine"

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_DB"
            value = var.db_name
          }

          env {
            name  = "POSTGRES_USER"
            value = var.db_user
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres_secret.metadata[0].name
                key  = "password"
              }
            }
          }

          # Subdiretório pgdata dentro do volume montado para evitar conflitos de arquivos ocultos
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.postgres_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# 5. Service ClusterIP para expor o Postgres internamente
resource "kubernetes_service_v1" "postgres_service" {
  metadata {
    name      = "postgres"
    namespace = "default"
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}
