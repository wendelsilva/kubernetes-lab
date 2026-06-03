# Política de Rede para Isolamento de Tráfego do Banco de Dados
resource "kubernetes_network_policy_v1" "postgres_net_policy" {
  metadata {
    name      = "postgres-network-policy"
    namespace = "default"
  }

  spec {
    # Alvo da política: Pods labeled 'app = postgres'
    pod_selector {
      match_labels = {
        app = "postgres"
      }
    }

    # Regras de Entrada (Ingress)
    ingress {
      # Origem permitida: Apenas pods labeled 'app = task-app'
      from {
        pod_selector {
          match_labels = {
            app = "task-app"
          }
        }
      }

      # Porta e protocolo permitidos
      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }

    # Habilita o controle do tráfego de entrada
    policy_types = ["Ingress"]
  }
}
