variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default = "hw1"
}

variable "location" {
  description = "Location for all resources"
  type        = string
  default = "eastus" 
}

variable "sa_name" {
  description = "Storage account name"
  type        = string
  default = "hw1st1"
}