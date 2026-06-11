variable "project" {
  description = "Project name, used as a prefix for resource names"
  type        = string
  default     = "homelab-aks"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.34.8"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "tm_routing_method" {
  description = "Traffic Manager routing method: Weighted (active/active) or Priority (active/passive)"
  type        = string
  default     = "Weighted"
}

variable "eastus_public_ip" {
  description = "Public IP of the eastus region-app-public service"
  type        = string
}

variable "westus2_public_ip" {
  description = "Public IP of the westus2 region-app-public service"
  type        = string
}
