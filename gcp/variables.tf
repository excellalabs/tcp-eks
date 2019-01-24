variable "project" {
  type        = "string"
  default     = "gke-tf-bench"
}
variable "network" {
  type        = "string"
  default     = "default"
}
variable "environment" {
  default     = "dev"
  description = "Environment i.e. prod or dev"
}
variable "region" {
  type        = "string"
  default     = "europe-west1"
}
variable "zone" {
  type        = "string"
  default     = "europe-west1-b"
}
variable "node_count" {
  type        = "string"
  default     = "3"
}
variable "node_name" {
  type        = "string"
  default     = "extra-node-pool"
}
variable "service_account" {
  type        = "string"
  default     = "service_account.json"
}