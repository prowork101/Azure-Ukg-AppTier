resource "azurerm_resource_group" "ukg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Project     = "Azure UKG App Tier"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "random_integer" "sql" {
  min = 1000
  max = 9999
}

resource "azurerm_virtual_network" "ukg" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.ukg.location
  resource_group_name = azurerm_resource_group.ukg.name

  tags = {
    Project     = "Azure UKG App Tier"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_subnet" "application_gateway" {
  name                 = "snet-application-gateway"
  resource_group_name  = azurerm_resource_group.ukg.name
  virtual_network_name = azurerm_virtual_network.ukg.name
  address_prefixes     = var.application_gateway_subnet_prefix
}

resource "azurerm_subnet" "application" {
  name                 = "snet-application"
  resource_group_name  = azurerm_resource_group.ukg.name
  virtual_network_name = azurerm_virtual_network.ukg.name
  address_prefixes     = var.app_subnet_prefix
}

resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.ukg.name
  virtual_network_name = azurerm_virtual_network.ukg.name
  address_prefixes     = var.data_subnet_prefix
}

resource "azurerm_network_security_group" "application" {
  name                = "nsg-application"
  location            = azurerm_resource_group.ukg.location
  resource_group_name = azurerm_resource_group.ukg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Project = "Azure UKG App Tier"
  }
}

resource "azurerm_subnet_network_security_group_association" "application" {
  subnet_id                 = azurerm_subnet.application.id
  network_security_group_id = azurerm_network_security_group.application.id
}

resource "azurerm_network_security_group" "database" {
  name                = "nsg-database"
  location            = azurerm_resource_group.ukg.location
  resource_group_name = azurerm_resource_group.ukg.name

  tags = {
    Project = "Azure UKG App Tier"
  }
}
resource "azurerm_public_ip" "application" {
  name                = "pip-ukg-app"
  location            = azurerm_resource_group.ukg.location
  resource_group_name = azurerm_resource_group.ukg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Project     = "Azure UKG App Tier"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_network_interface" "application" {
  name                = "nic-ukg-app"
  location            = azurerm_resource_group.ukg.location
  resource_group_name = azurerm_resource_group.ukg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.application.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.application.id
  }

  tags = {
    Project     = "Azure UKG App Tier"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_linux_virtual_machine" "application" {
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.ukg.name
  location                        = azurerm_resource_group.ukg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.application.id
  ]

  os_disk {
    name                 = "osdisk-ukg-app"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server-arm64"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
      <title>UKG-Style HR Platform</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          text-align: center;
          padding-top: 80px;
          background: #f4f7fb;
        }
        .card {
          background: white;
          max-width: 650px;
          margin: auto;
          padding: 40px;
          border-radius: 12px;
          box-shadow: 0 4px 18px rgba(0,0,0,0.12);
        }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>Enterprise HR SaaS Platform</h1>
        <p>UKG-style application hosted on Microsoft Azure.</p>
        <p>Application Tier: Online</p>
      </div>
    </body>
    </html>
    HTML

    systemctl enable nginx
    systemctl restart nginx
  EOF
  )

  tags = {
    Project     = "Azure UKG App Tier"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_public_ip" "application_gateway" {
  name                = "pip-agw-ukg"
  location            = azurerm_resource_group.ukg.location
  resource_group_name = azurerm_resource_group.ukg.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_application_gateway" "ukg" {

  name                = var.application_gateway_name
  location            = azurerm_resource_group.ukg.location
  resource_group_name = azurerm_resource_group.ukg.name

  sku {
    name     = var.application_gateway_sku
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.application_gateway.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.application_gateway.id
  }

  backend_address_pool {
    name = "backend-pool"

    ip_addresses = [
      azurerm_network_interface.application.private_ip_address
    ]
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
  }
}

resource "azurerm_mssql_server" "database" {
  name                = "sql-ukg-app-${random_integer.sql.result}"
  resource_group_name = azurerm_resource_group.ukg.name
  location            = azurerm_resource_group.ukg.location
  version             = "12.0"

  administrator_login          = "sqladminuser"
  administrator_login_password = "Novnovo07!"

  minimum_tls_version = "1.2"

  tags = {
    Project     = "Azure UKG App Tier"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_mssql_database" "database" {
  name      = "ukgdb"
  server_id = azurerm_mssql_server.database.id
  sku_name  = "Basic"

  tags = {
    Project     = "Azure UKG App Tier"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-ukg"
  location            = azurerm_resource_group.ukg.location
  resource_group_name = azurerm_resource_group.ukg.name
  subnet_id           = azurerm_subnet.data.id

  private_service_connection {
    name                           = "sql-connection"
    private_connection_resource_id = azurerm_mssql_server.database.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  tags = {
    Project     = "Azure UKG App Tier"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}