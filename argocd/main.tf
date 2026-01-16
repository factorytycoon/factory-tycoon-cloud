resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.2"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  values = [
    yamlencode({
      configs = {
        cm = {
          "resource.exclusions" = <<-EOT
            - apiGroups:
              - "v1.metrics.eks.amazonaws.com"
              kinds:
              - "*"
              clusters:
              - "*"
          EOT
        }
      }
    })
  ]
}

resource "kubernetes_secret_v1" "argocd_repo" {
  metadata {
    name      = "repo-factory-tycoon"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  type = "Opaque"

  data = {
    url      = "https://github.com/lgcns5team/factory-tycoon-k8s"
    username = var.github_username
    password = var.github_pat
  }
}
