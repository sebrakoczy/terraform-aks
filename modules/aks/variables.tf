variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_vm_size" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vnet_id" {
  description = "VNet ID for Network Contributor role assignment (needed for internal LoadBalancers)"
  type        = string
}
