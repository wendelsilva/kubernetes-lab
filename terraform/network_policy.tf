resource "kubernetes_network_policy_v1" "postgres_net_policy" {
  metadata {
    name      = "postgres-network-policy"
    namespace = "default"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "postgres"
      }
    }

    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "task-app"
          }
        }
      }

      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}
