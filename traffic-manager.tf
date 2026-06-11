resource "random_string" "tm_suffix" {
  count = terraform.workspace == "default" ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "tm" {
  count = terraform.workspace == "default" ? 1 : 0
  name     = "rg-${var.project}-${var.environment}-tm"
  location = "eastus"
  tags     = var.tags
}

resource "azurerm_traffic_manager_profile" "main" {
  count = terraform.workspace == "default" ? 1 : 0
  name                   = "tm-${var.project}-${var.environment}-${random_string.tm_suffix[0].result}"
  resource_group_name    = azurerm_resource_group.tm[0].name
  traffic_routing_method = var.tm_routing_method

  dns_config {
    relative_name = "tm-${var.project}-${var.environment}-${random_string.tm_suffix[0].result}"
    ttl           = 30
  }

  monitor_config {
    protocol = "HTTP"
    port     = 80
    path     = "/"
    interval_in_seconds = 30
    timeout_in_seconds  = 9
    tolerated_number_of_failures = 3
  }

  tags = var.tags
}

resource "azurerm_traffic_manager_external_endpoint" "eastus" {
  count = terraform.workspace == "default" ? 1 : 0
  name              = "eastus-endpoint"
  profile_id        = azurerm_traffic_manager_profile.main[0].id
  target            = var.eastus_public_ip
  weight            = 100
  priority          = 1
  endpoint_location = "eastus"
}

resource "azurerm_traffic_manager_external_endpoint" "westus2" {
  count = terraform.workspace == "default" ? 1 : 0
  name              = "westus2-endpoint"
  profile_id        = azurerm_traffic_manager_profile.main[0].id
  target            = var.westus2_public_ip
  weight            = 100
  priority          = 2
  endpoint_location = "westus2"
}

output "traffic_manager_fqdn" {
  value = try(azurerm_traffic_manager_profile.main[0].fqdn, null)
}
