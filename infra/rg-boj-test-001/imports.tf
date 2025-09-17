# Terraform import blocks for AVM modules

# Virtual Network 1
import {
  to = module.vnet_boj_test_001_001.azurerm_virtual_network.this
  id = "/subscriptions/<subscription_id>/resourceGroups/rg-boj-test-001/providers/Microsoft.Network/virtualNetworks/vnet-boj-test-001-001"
}
import {
  to = module.vnet_boj_test_001_001.azurerm_subnet.subnet1
  id = "/subscriptions/<subscription_id>/resourceGroups/rg-boj-test-001/providers/Microsoft.Network/virtualNetworks/vnet-boj-test-001-001/subnets/subnet-boj-test-001-001-001"
}
import {
  to = module.vnet_boj_test_001_001.azurerm_subnet.subnet2
  id = "/subscriptions/<subscription_id>/resourceGroups/rg-boj-test-001/providers/Microsoft.Network/virtualNetworks/vnet-boj-test-001-001/subnets/subnet-boj-test-001-001-002"
}

# Virtual Network 2
import {
  to = module.vnet_boj_test_001_002.azurerm_virtual_network.this
  id = "/subscriptions/<subscription_id>/resourceGroups/rg-boj-test-001/providers/Microsoft.Network/virtualNetworks/vnet-boj-test-001-002"
}
import {
  to = module.vnet_boj_test_001_002.azurerm_subnet.subnet1
  id = "/subscriptions/<subscription_id>/resourceGroups/rg-boj-test-001/providers/Microsoft.Network/virtualNetworks/vnet-boj-test-001-002/subnets/subnet-boj-test-001-002-001"
}

# Storage Account
import {
  to = module.storage_boj_test_001.azurerm_storage_account.this
  id = "/subscriptions/<subscription_id>/resourceGroups/rg-boj-test-001/providers/Microsoft.Storage/storageAccounts/stgbojtest001"
}

# Replace <subscription_id> with your actual Azure subscription ID.
