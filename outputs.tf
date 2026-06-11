output "resource_group_name" {
  value = try(azurerm_resource_group.main[0].name, null)
}

output "aks_cluster_name" {
  value = try(module.aks[0].cluster_name, null)
}

output "aks_kube_config_command" {
  description = "Run this to configure kubectl"
  value       = try("az aks get-credentials --resource-group ${azurerm_resource_group.main[0].name} --name ${module.aks[0].cluster_name}", null)
}

output "acr_login_server" {
  value = try(module.acr[0].login_server, null)
}
