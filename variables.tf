variable "location" {
 description = "The location where resources will be created"
 default     = "East Us"
 type = string
}

variable "tags" {
 description = "A map of the tags to use for the resources that are deployed"
 type        = map(string)

 default = {
   environment = "test"
 }
}

variable "resource_group_name" {
 description = "The name of the resource group in which the resources will be created"
 default     = "VMSS"
 type = string
}

# variable "azurerm_network_interface"{
#   description = "The network interface for the Controller machine"
# }
# variable "resource_group_names" {
#   type    = map
#   default = {
#     dev  = "dev-rg"
#     test = "test-rg"
#     prod = "prod-rg"
#   }
# }


locals {
  regions_with_availability_zones = ["eastus"] #["centralus","eastus2","eastus","westus"]
  zones = contains(local.regions_with_availability_zones, var.location) ? list("1","2","3") : null
}



variable "azurerm_virtual_network" {
 description = "The name of the virtual network in which the resources will be created"
 default     = "VMSSnet"
 type = string
}

variable "azurerm_virtual_machine_scale_set" {
 description = "The name of the virtual network in which the resources will be created"
 default     = "VMScaleSet"
 type = string
}

variable "availability_zone_names" {
 description = "The name of the virtual network in which the resources will be created"
 default     = ["eastus"]
 type    = list(string)
}



#variable "application_port" {
#   description = "The port that you want to expose to the external load balancer"
 #  default     = 8080
#}

##idan
#variable "application_port2" {
 #  description = "The port that you want to expose to the external load balancer"
  # default     = 22
#}
variable "admin_user" {
   description = "User name to use as the admin account on the VMs that will be part of the VM Scale Set"
}

variable "admin_password" {
   description = "Default password for admin account"
   }

variable vmss_instance_number{
  description ="The number of max instances of the vmss"
  default = 3
}
 locals {
  infra_env=terraform.workspace
 }

  variable "controller_linux_virtual_machine_name"{
    description ="The name of the linux virtual machine"
    default = "controllerVM"
  }


# variable "infra_env" {
#   default=terraform.workspace
#   description = "The current terraform workspace that we are working in"
# }




# variable "cloudconfig_file" {
#   description = "The location of the cloud init configuration file."
# }


# variable "workspace_to_environment_map" {
#   type = map(string)
#   default = {
#     dev     = "dev"
#     qa      = "qa                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           "
#     prod    = "prod"
#   }
# }


