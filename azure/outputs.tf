# Outputs
output "Azure_kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.k8s.name
}
output "Azure_resource_group_name" {
  value = azurerm_resource_group.rg.name
}