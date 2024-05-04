# Helm

data "azurerm_kubernetes_cluster" "credentials" {
  name                = azurerm_kubernetes_cluster.k8s.name
  resource_group_name = azurerm_resource_group.rg.name
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.credentials.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.cluster_ca_certificate)
    config_path            = "~/.kube/config"
  }
}


resource "helm_release" "hello_world_azure" {
  name       = "hello"
  repository = "https://cloudecho.github.io/charts/"
  chart      = "hello"
  namespace = "default"

  values = [
    file("${path.module}/hello-values-azure.yaml")
  ]
}

# data "kubernetes_ingress_v1" "ingress_hostname" {
#   metadata {
#     name = "hello"
#     namespace = kubernetes_namespace.vic-ns.metadata[0].name
#   }
# }

