resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]

  depends_on = [
    azapi_resource.ssh_public_key
  ]
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  depends_on = [
    random_pet.ssh_key_name
  ]
}

output "azure_key_data" {
  value = "${azapi_resource_action.ssh_public_key_gen.output.publicKey}"

  sensitive = true
}

# Generate Resource group name
resource "random_pet" "rg_name" {
  prefix = "vic-rg"
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id

  depends_on = [
    random_pet.rg_name
  ]
}

resource "random_pet" "azurerm_kubernetes_cluster_name" {
  prefix = "vic-cluster"
}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}


provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.k8s.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}

data "azurerm_kubernetes_cluster" "k8s" {
  name                = azurerm_kubernetes_cluster.k8s.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.rg.location
  name                = random_pet.azurerm_kubernetes_cluster_name.id
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = random_pet.azurerm_kubernetes_cluster_dns_prefix.id

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = var.node_count
  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = "${azapi_resource_action.ssh_public_key_gen.output.publicKey}"
    }
  }
  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
  }
}



