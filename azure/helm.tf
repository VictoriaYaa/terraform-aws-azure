# Helm

resource "kubernetes_namespace" "vic" {
  metadata {
    name = var.namespace
  }
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.credentials.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.cluster_ca_certificate)

  }
}

resource "helm_release" "hello_world_azure" {
  name       = "hello"
  repository = "https://cloudecho.github.io/charts/"
  chart      = "hello"
  namespace = kubernetes_namespace.vic-ns.metadata[0].name
}