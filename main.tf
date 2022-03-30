# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

#Creating resource group
resource "azurerm_resource_group" "vmss" {
 name     = var.resource_group_name 
 location = var.location
 tags = {
        environment = "${terraform.workspace}"
    }
}
# Generate random text for a unique domain name

resource "random_string" "fqdn" {
 length  = 6
 special = false
 upper   = false
 number  = false
}
#creating network security group for public subnet

resource "azurerm_network_security_group" "vmss" {
    name                = "${terraform.workspace}_nsg"
    location            = var.location
    resource_group_name = azurerm_resource_group.vmss.name
    
    security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP:8080"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    tags = {
        environment = "${terraform.workspace}"
    }
}


# Connect the vmss-nsg to the public network interface
resource "azurerm_subnet_network_security_group_association" "vmss" {
  subnet_id                 = azurerm_subnet.vmss.id
  network_security_group_id = azurerm_network_security_group.vmss.id
}



# Create virtual network
resource "azurerm_virtual_network" "vmss" {
 name                = var.azurerm_virtual_network
 address_space       = ["10.0.0.0/16"]
 location            = var.location
 resource_group_name = azurerm_resource_group.vmss.name
 tags = {
        environment = "${terraform.workspace}"
    }
}
#Configure the private subnet
resource "azurerm_subnet" "vmss2" {
 name                 = "private"
 resource_group_name  = azurerm_resource_group.vmss.name
 virtual_network_name = azurerm_virtual_network.vmss.name
 address_prefixes       = ["10.0.2.0/24"]
}
#Configure the public subnet
resource "azurerm_subnet" "vmss" {
 name                 = "public"
 resource_group_name  = azurerm_resource_group.vmss.name
 virtual_network_name = azurerm_virtual_network.vmss.name
 address_prefixes       = ["10.0.1.0/24"]
}
# Create public IPs
resource "azurerm_public_ip" "vmss" {
 name                         = "vmss-public-ip"
 location                     = var.location
 resource_group_name          = azurerm_resource_group.vmss.name
 allocation_method = "Static"
 domain_name_label            = random_string.fqdn.result
 tags = {
        environment = "${terraform.workspace}"
    }
}
#Creating loadbalancer with frontend ip
resource "azurerm_lb" "vmss" {
 name                = "vmss-lb"
 location            = var.location
 resource_group_name = azurerm_resource_group.vmss.name

 frontend_ip_configuration {
   name                 = "PublicIPAddress"
   public_ip_address_id = azurerm_public_ip.vmss.id
 }

 tags = {
        environment = "${terraform.workspace}"
    }
}
#Creating lb backend pool
resource "azurerm_lb_backend_address_pool" "bpepool" {
 loadbalancer_id     = azurerm_lb.vmss.id
 name                = "BackEndAddressPool"
}
#Creating lb prob for port 8080
resource "azurerm_lb_probe" "vmss2" {
 loadbalancer_id     = azurerm_lb.vmss.id
 name                = "http-running-probe"
 port                = 8080
}
#Creating lb prob for port 22
resource "azurerm_lb_probe" "vmss" {
#  resource_group_name = azurerm_resource_group.vmss.name
 loadbalancer_id     = azurerm_lb.vmss.id
 name                = "ssh-running-probe"
 port                = 22
}
#Adding lb rules for ports 8080 and 22
resource "azurerm_lb_rule" "httpRule" {
   loadbalancer_id                = azurerm_lb.vmss.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = 8080
   backend_port                   = 8080
   backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]    #idan2
   frontend_ip_configuration_name = "PublicIPAddress"
   probe_id                       = azurerm_lb_probe.vmss2.id
}

resource "azurerm_lb_rule" "sshRule" {
   loadbalancer_id                = azurerm_lb.vmss.id
   name                           = "ssh"
   protocol                       = "Tcp"
   frontend_port                  = 22
   backend_port                   = 22
   backend_address_pool_ids        = [azurerm_lb_backend_address_pool.bpepool.id] #idan2
   frontend_ip_configuration_name = "PublicIPAddress"
   probe_id                       = azurerm_lb_probe.vmss.id
}


#Setup a virtual machine scale-set
resource "azurerm_virtual_machine_scale_set" "vmss" {
 name                = var.azurerm_virtual_machine_scale_set
 location            = var.location
 resource_group_name = azurerm_resource_group.vmss.name
 upgrade_policy_mode = "Manual"

 zones = local.zones

 sku {
   name     = "Standard_DS1_v2"
   tier     = "Standard"
   capacity = 2
 }

 storage_profile_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "16.04-LTS"
   version   = "latest"
 }

 storage_profile_os_disk {
   name              = ""
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 storage_profile_data_disk {
   lun          = 0
   caching        = "ReadWrite"
   create_option  = "Empty"
   disk_size_gb   = 10
 }

 os_profile {
   computer_name_prefix = "vmlab"
   admin_username       = var.admin_user
   admin_password       = var.admin_password
  #  custom_data          = file("./cloudinit.conf")
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 network_profile {
   name    = "terraformnetworkprofile"
   primary = true

   ip_configuration {
     name                                   = "IPConfiguration"
     subnet_id                              = azurerm_subnet.vmss.id
     load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
     primary = true
   }
 }

tags = {
        environment = "${terraform.workspace}"
    }
}
# Data template Bash bootstrapping file
# data "local_file" "cloudinit" {
#     filename = "${path.module}/cloudinit.conf"
# }

#Setting azure monitor auto-scaling
resource "azurerm_monitor_autoscale_setting" "vmss" {
  name                = "AutoscaleSetting"
  resource_group_name = azurerm_resource_group.vmss.name
  location            = azurerm_resource_group.vmss.location
  target_resource_id  = azurerm_virtual_machine_scale_set.vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 2
      minimum = 2
      maximum = var.vmss_instance_number
      # maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["admin@contoso.com"]
    }
  }
}




#Adding azure postgresql as a service
resource "azurerm_postgresql_server" "example" {
  name                = "pssql-${terraform.workspace}"
  location            = azurerm_resource_group.vmss.location
  resource_group_name = azurerm_resource_group.vmss.name

  administrator_login          = "psqladmin"
  administrator_login_password = "H@Sh1CoR3!"

  sku_name   = "GP_Gen5_2"
  version    = "11"
  storage_mb = 51200

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  #public_network_access_enabled    = false
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}


#Configure the postgres sql firewall rule- allow connection from the lb front ip
resource "azurerm_postgresql_firewall_rule" "dbFWrule1" {
  name                = "postgres"
  resource_group_name = azurerm_resource_group.vmss.name
  server_name         = azurerm_postgresql_server.example.name
  # start_ip_address    = "20.231.212.91"
  # end_ip_address      = "20.231.212.91"
  start_ip_address    = "${azurerm_public_ip.vmss.ip_address}"
  end_ip_address      = "${azurerm_public_ip.vmss.ip_address}"
}



#Create network interfaces
#create controller interface
resource "azurerm_network_interface" "controller_nic" {
  name                = "vnetController-${terraform.workspace}"
  location            = azurerm_resource_group.vmss.location
  resource_group_name = azurerm_resource_group.vmss.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.vmss.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.controller_nic.id
  }

  tags = {
        environment = "${terraform.workspace}"
    }
}

# Create webApp virtual machine Controler for ansible
resource "azurerm_linux_virtual_machine" "controller" {
  name                  = var.controller_linux_virtual_machine_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.controller_nic.id]
  size                  = "Standard_B1s" #change to B1s
  admin_username = var.admin_user
  admin_password = var.admin_password
  computer_name         = "Controller-Server"

  #Uncomment this line to delete the OS disk automatically when deleting the VM
  #delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true
  disable_password_authentication = false
  
  os_disk {
    name              = "webAppDisk1"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer                 = "0001-com-ubuntu-server-focal"
    publisher             = "Canonical"
    sku                   = "20_04-lts-gen2"
    version   = "latest"

  }
  

  tags = {
        environment = "${terraform.workspace}"
    }
}