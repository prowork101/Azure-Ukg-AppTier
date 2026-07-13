variable "resource_group_name" {
  default = "rg-ukg-app-tier"
}

variable "location" {
  default = "East US"
}

variable "environment" {
  default = "Development"
}
variable "vnet_name" {
  description = "Name of the Azure Virtual Network"
  type        = string
  default     = "vnet-ukg-app"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "application_gateway_subnet_prefix" {
  description = "Address range for the Application Gateway subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "app_subnet_prefix" {
  description = "Address range for the application subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "data_subnet_prefix" {
  description = "Address range for the data subnet"
  type        = list(string)
  default     = ["10.0.3.0/24"]
}
variable "vm_name" {
  description = "Name of the application virtual machine"
  type        = string
  default     = "vm-ukg-app"
}

variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Administrator password for the VM"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B1s"
}
variable "application_gateway_name" {
  default = "agw-ukg-app"
}

variable "application_gateway_sku" {
  default = "Standard_v2"
}

variable "sql_admin_username" {
  description = "Administrator username for Azure SQL"
  type        = string
  default     = "sqladminuser"
}

variable "sql_admin_password" {
  description = "Administrator password for Azure SQL"
  type        = string
  sensitive   = true
}