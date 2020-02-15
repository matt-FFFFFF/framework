terraform {
    required_version = "> 0.12.0"
    backend "azurerm" {
        storage_account_name = "psaeuwshared"
        container_name       = "terraform-state"
        key                  = "core.mtjw.azure.tfstate"
    }
}

provider "azurerm" {
    version = "=1.41.0"
}

provider "azuread" {
    version = "=0.7.0"
}

data "azurerm_client_config" "current" {}

module "core_infrastructure" {
    source = "./modules/core"
    location = var.location
    tenant_id = data.azurerm_client_config.current.tenant_id
    service_principal_object_id = data.azurerm_client_config.current.object_id
    ssh_file_location = var.ssh_file_location
}

module "aks_cluster" {
    source = "./modules/aks"
    role = "aks"
    instance_id = "1"
    location = var.location
    resource_group_name = module.core_infrastructure.resource_group_name
    virtual_network_name = module.core_infrastructure.virtual_network_name
    key_vault_id = module.core_infrastructure.key_vault_id
    ssh_key_name = module.core_infrastructure.ssh_key_name
    log_analytics_workspace_id = module.core_infrastructure.log_analytics_workspace_id
}

module "private_aks" {
    source = "./modules/private-aks"
    location = var.location
    core_resource_group_name = module.core_infrastructure.resource_group_name
    core_network_id = module.core_infrastructure.virtual_network_id
    core_network_name = module.core_infrastructure.virtual_network_name
    key_vault_id = module.core_infrastructure.key_vault_id
    ssh_key_name = module.core_infrastructure.ssh_key_name
    log_analytics_workspace_id = module.core_infrastructure.log_analytics_workspace_id
}
