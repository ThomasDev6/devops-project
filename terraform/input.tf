# Resource Group/Location
variable "location" {}
variable "resource_group" {}
variable "acr_name" {}
variable "cluster_kubernetes_name" {}
variable "public_ip_name" {}
variable "user_object_id" {
  description = "The object ID of the user"
  type        = string
}