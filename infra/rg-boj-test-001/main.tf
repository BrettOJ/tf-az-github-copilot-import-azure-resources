# AVM-first: All resources use Azure Verified Modules

module "vnet_boj_test_001_001" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.10.0"
  name                = "vnet-boj-test-001-001"
  resource_group_name = "rg-boj-test-001"
  location            = "australiaeast"
  address_space       = ["10.0.0.0/16"]
  subnets = {
    subnet1 = {
      name             = "subnet-boj-test-001-001-001"
      address_prefixes = ["10.0.1.0/24"]
    }
    subnet2 = {
      name             = "subnet-boj-test-001-001-002"
      address_prefixes = ["10.0.2.0/24"]
    }
  }
}

module "vnet_boj_test_001_002" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.10.0"
  name                = "vnet-boj-test-001-002"
  resource_group_name = "rg-boj-test-001"
  location            = "australiaeast"
  address_space       = ["10.1.0.0/16"]
  subnets = {
    subnet1 = {
      name             = "subnet-boj-test-001-002-001"
      address_prefixes = ["10.1.1.0/24"]
    }
  }
}

module "storage_boj_test_001" {
  source              = "Azure/avm-res-storage-storageaccount/azurerm"
  version             = "0.6.4"
  name                = "stgbojtest001"
  resource_group_name = "rg-boj-test-001"
  location            = "australiaeast"
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  tags = {
    environment = "dev"
  }
}
