terraform {
    required_version = "> 0.12.0"
    backend "azurerm" {}
}

provider "azurerm" {
    version = ">=2.0.0"
    features {
        virtual_machine {
            delete_os_disk_on_deletion = true
        }
    }
}

provider "azuread" {
    version = ">=0.7.0"
}

data "azurerm_client_config" "current" {}

locals {
    azure_region_code = var.azure_regions[var.azure_region]
    environment_code = var.environments[var.environment]
}

module "core_infrastructure" {
    source = "./modules/core"
    name = var.name
    network_id = var.network_id
    location = var.azure_region
    azure_region_code = local.azure_region_code
    environment = local.environment_code
    tenant_id = data.azurerm_client_config.current.tenant_id
    service_principal_object_id = data.azurerm_client_config.current.object_id
    ssh_file_location = var.ssh_file_location
}

module "private_network" {
    source = "./modules/private-network"
    name = var.name
    network_id = var.network_id
    location = var.azure_region
    azure_region_code = local.azure_region_code
    environment = local.environment_code
    resource_group_name = module.core_infrastructure.resource_group_name
    virtual_network_name = module.core_infrastructure.virtual_network_name
    key_vault_id = module.core_infrastructure.key_vault_id
    ssh_key_name = module.core_infrastructure.ssh_key_name
    enable_diagnostics = true
    log_analytics_workspace_id = module.core_infrastructure.log_analytics_workspace_id
    //storage_account = module.core_infrastructure.storage_account_uri
}


module "aks_cluster" {
    source = "./modules/aks"
    name = "aks"
    instance_id = "1"
    network_id = var.network_id
    location = var.azure_region
    azure_region_code = local.azure_region_code
    environment = local.environment_code
    resource_group_name = module.core_infrastructure.resource_group_name
    virtual_network_name = module.core_infrastructure.virtual_network_name
    key_vault_id = module.core_infrastructure.key_vault_id
    ssh_key_name = module.core_infrastructure.ssh_key_name
    log_analytics_workspace_id = module.core_infrastructure.log_analytics_workspace_id
}

module "private_aks" {
    source = "./modules/private-aks"
    name = "aks-private"
    instance_id = "1"
    network_id = var.aks_private_network_id
    location = var.azure_region
    azure_region_code = local.azure_region_code
    environment = local.environment_code
    core_resource_group_name = module.core_infrastructure.resource_group_name
    core_network_id = module.core_infrastructure.virtual_network_id
    core_network_name = module.core_infrastructure.virtual_network_name
    key_vault_id = module.core_infrastructure.key_vault_id
    ssh_key_name = module.core_infrastructure.ssh_key_name
    log_analytics_workspace_id = module.core_infrastructure.log_analytics_workspace_id
    firewall_name = module.private_network.firewall_name
    firewall_private_ip_address = module.private_network.firewall_private_ip_address
    firewall_resource_group_name = module.core_infrastructure.resource_group_name
}

module "encrypted_vm" {
  source = "./modules/linux-vm"
  name = "encvm"
  location = var.azure_region
  azure_region_code = local.azure_region_code
  environment = local.environment_code
  resource_group_name = module.core_infrastructure.resource_group_name
  subnet_id = module.core_infrastructure.general_subnet_id
  key_vault_id = module.core_infrastructure.key_vault_id
  ssh_key_name = module.core_infrastructure.ssh_key_name
  //storage_account = module.core_infrastructure.storage_account_uri
  data_disks = {
      1 = 250,
      2 = 500
  }
}
