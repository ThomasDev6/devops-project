terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.83.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_main" {
  name     = var.resource_group
  location = var.location
  tags = {
    environment = "esgi devops project"
  }
}

resource "azurerm_container_registry" "acr" {
  name                   = var.acr_name
  resource_group_name    = azurerm_resource_group.rg_main.name
  location               = azurerm_resource_group.rg_main.location
  sku                    = "Standard"
  admin_enabled          = true
  tags = {
    environment = "esgi devops project"
  }
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_kubernetes_name
  resource_group_name = azurerm_resource_group.rg_main.name
  location            = azurerm_resource_group.rg_main.location
  dns_prefix = "testdevopsproj"

  default_node_pool {
    name       = "default"
    vm_size    = "Standard_B2s"
    node_count = 1
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "esgi devops project"
  }

}

resource "azurerm_public_ip" "public_ip_address" {
  name                = var.public_ip_name
  // https://stackoverflow.com/questions/75247192/whats-the-correct-way-to-setup-aks-cluster-static-ip-load-balancer-and-ingress
  resource_group_name = azurerm_kubernetes_cluster.k8s.node_resource_group
  location            = azurerm_resource_group.rg_main.location
  allocation_method   = "Static"
  // https://stackoverflow.com/questions/64740298/how-to-expose-an-azure-kubernetes-cluster-with-a-public-ip-address-using-terrafo
  sku =  "Standard"
  tags = {
    environment = "esgi devops project"
  }
}

// pour l'utilisation de kubelet_identity
// https://stackoverflow.com/questions/59978060/how-to-give-permissions-to-aks-to-access-acr-via-terraform

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.user_object_id
}