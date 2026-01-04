resource "kubernetes_manifest" "argocd_backend_websocket_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "factory-tycoon-backend-websocket"
      namespace = "argocd"
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/lgcns5team/factory-tycoon-k8s"
        targetRevision = "main"
        path           = "helm/factory-tycoon-websocket"
        helm = {
          releaseName = "factory-tycoon-websocket"
          valueFiles = [
            "values.yaml",
            "values-prod.yaml"
          ]
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}
