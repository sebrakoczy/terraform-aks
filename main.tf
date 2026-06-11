locals {
  region_config = {
    default = {
      location           = "eastus"
      vnet_address_space = ["10.99.0.0/16"]
      aks_subnet_prefix  = ["10.99.1.0/24"]
    }
    eastus = {
      location           = "eastus"
      vnet_address_space = ["10.10.0.0/16"]
      aks_subnet_prefix  = ["10.10.1.0/24"]
    }
    westus2 = {
      location           = "westus2"
      vnet_address_space = ["10.20.0.0/16"]
      aks_subnet_prefix  = ["10.20.1.0/24"]
    }
  }

  cfg = local.region_config[terraform.workspace]

  name_prefix = "${var.project}-${var.environment}-${terraform.workspace}"

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    Region      = terraform.workspace
  })
}

resource "azurerm_resource_group" "main" {
  count    = terraform.workspace == "default" ? 0 : 1
  name     = "rg-${local.name_prefix}"
  location = local.cfg.location
  tags     = local.tags
}

module "networking" {
  count  = terraform.workspace == "default" ? 0 : 1
  source = "./modules/networking"

  name_prefix         = local.name_prefix
  location            = local.cfg.location
  resource_group_name = azurerm_resource_group.main[0].name
  vnet_address_space  = local.cfg.vnet_address_space
  aks_subnet_prefix   = local.cfg.aks_subnet_prefix
  tags                = local.tags
}

module "acr" {
  count  = terraform.workspace == "default" ? 0 : 1
  source = "./modules/acr"

  name_prefix         = local.name_prefix
  location            = local.cfg.location
  resource_group_name = azurerm_resource_group.main[0].name
  tags                = local.tags
}

module "aks" {
  count  = terraform.workspace == "default" ? 0 : 1
  source = "./modules/aks"

  name_prefix         = local.name_prefix
  location            = local.cfg.location
  resource_group_name = azurerm_resource_group.main[0].name
  kubernetes_version  = var.kubernetes_version
  node_count          = var.node_count
  node_vm_size        = var.node_vm_size
  subnet_id           = module.networking[0].aks_subnet_id
  acr_id              = module.acr[0].acr_id
  vnet_id             = module.networking[0].vnet_id
  tags                = local.tags
}
