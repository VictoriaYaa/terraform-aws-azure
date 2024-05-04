# Helm

# resource "kubernetes_namespace" "vic-ns" {
#   metadata {
#     name = var.namespace
#   }
# }

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

  }
}

# resource "helm_release" "hello_world_azure" {
#   name       = "hello"
#   repository = "https://cloudecho.github.io/charts/"
#   chart      = "hello"
#   namespace = kubernetes_namespace.vic-ns.metadata[0].name

#   values = [
#     templatefile("${path.module}/hello-values-azure.yaml",{ host = "${data.kubernetes_ingress_v1.ingress_hostname.status.0.load_balancer.0.ingress.0.hostname}" })
#   ]
# }

# data "kubernetes_ingress_v1" "ingress_hostname" {
#   metadata {
#     name = "hello"
#     namespace = kubernetes_namespace.vic-ns.metadata[0].name
#   }
# }

# resource "helm_release" "alb-controller" {
#  name       = "aws-load-balancer-controller"
#  repository = "https://aws.github.io/eks-charts"
#  chart      = "aws-load-balancer-controller"
#  namespace  = kubernetes_namespace.vic-ns.metadata[0].name

#  set {
#      name  = "region"
#      value = var.resource_group_location
#  }

#  set {
#      name  = "image.repository"
#      value = "602401143452.dkr.ecr.${var.resource_group_location}.amazonaws.com/amazon/aws-load-balancer-controller"
#  }

#  set {
#      name  = "serviceAccount.create"
#      value = "true"
#  }

#  set {
#     name  = "rbac.create"
#     value = "true"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = var.service_account_name
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.kubernetes_alb_controller[0].arn
#   }

#   set {
#     name  = "enableServiceMutatorWebhook"
#     value = "true"
#   }

#  set {
#      name  = "clusterName"
#      value = azurerm_kubernetes_cluster.k8s.name
#  }
#  }

