resource "kubernetes_manifest" "argocd_backend_sensor_stream_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "factory-tycoon-backend-sensor-stream"
      namespace = "argocd"
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/lgcns5team/factory-tycoon-k8s"
        targetRevision = "main"
        path           = "be-sensor-stream"   
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
