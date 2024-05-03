provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

resource "kubernetes_namespace" "vic-ns" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "hello_world" {
  name       = "hello"
  repository = "https://cloudecho.github.io/charts/"
  chart      = "hello"
  namespace = kubernetes_namespace.vic-ns.metadata[0].name

  values = [
    templatefile("${path.module}/hello-values.yaml",{ host = "${data.kubernetes_ingress_v1.ingress_hostname.status.0.load_balancer.0.ingress.0.hostname}" })
  ]
}

data "kubernetes_ingress_v1" "ingress_hostname" {
  metadata {
    name = "hello"
    namespace = kubernetes_namespace.vic-ns.metadata[0].name
  }
}

output "kubernetes_ingress" {
  description   = "External DN name of load balancer"
  value         = data.kubernetes_ingress_v1.ingress_hostname.status.0.load_balancer.0.ingress.0.hostname
}


resource "helm_release" "alb-controller" {
 name       = "aws-load-balancer-controller"
 repository = "https://aws.github.io/eks-charts"
 chart      = "aws-load-balancer-controller"
 namespace  = kubernetes_namespace.vic-ns.metadata[0].name

 set {
     name  = "region"
     value = var.aws_region
 }

 set {
     name  = "vpcId"
     value = module.vpc.vpc_id
 }

 set {
     name  = "image.repository"
     value = "602401143452.dkr.ecr.${var.aws_region}.amazonaws.com/amazon/aws-load-balancer-controller"
 }

 set {
     name  = "serviceAccount.create"
     value = "true"
 }

 set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.kubernetes_alb_controller[0].arn
  }

  set {
    name  = "enableServiceMutatorWebhook"
    value = "true"
  }

 set {
     name  = "clusterName"
     value = local.cluster_name
 }
 }

 resource "aws_iam_policy" "kubernetes_alb_controller" {
  depends_on  = [var.mod_dependency]
  count       = var.enabled ? 1 : 0
  name        = "${local.cluster_name}-alb-controller"
  path        = "/"
  description = "Policy for load balancer controller service"

  policy = file("${path.module}/alb_controller_iam_policy.json")
}