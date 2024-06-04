@description('The name of the managed identity resource.')
param managedIdentityName string

@description('The IDs of the role definitions to assign to the managed identity - Blob Reader ID')
param roleDefinitionIds array = [
  '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
]

@description('An optional description to apply to each role assignment')
param roleAssignmentDescription string = ''

@description('The Azure location where the managed identity should be created.')
param location string = resourceGroup().location

@description('Name of the Virtual Machine Scale Set')
param vmssName string

@description('Allowed Windows OS versions')
@allowed([
  '2019-DataCenter-GenSecond'
  '2016-DataCenter-GenSecond'
  '2022-datacenter-azure-edition'
])
param windowsOSVersion string = '2022-datacenter-azure-edition'

@description('Size of VMs in the VM Scale Set.')
param skuName string = 'Standard_D2s_v3'

@description('Number of VM instances (100 or less).')
@minValue(1)
@maxValue(100)
param instanceCount int = 3

@description('Administrator login')
param adminUsername string

@description('Administrator password')
@secure()
param adminPassword string

@description('Subscription ID')
param subscriptionId string

@description('Resource Group ID')
param resourceGroupId string

@description('Virtual Network Name')
param virtualNetworkName string

@description('Subnet Name')
param subnetName string

@description('OS disk creation option')
param osDiskCreateOption string = 'FromImage'

@description('URI to file')
param scriptUri string

@description('Client ID of the managed identity for downloading files')
param managedIdentityClientId string

// @description('Password to .zip file with PowerShell (if exist)')
// @secure()
// param scriptUriSasToken string

var imageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: windowsOSVersion
  version: 'latest'
}
var subnetResourceId = resourceId(subscriptionId, resourceGroupId, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)

var roleAssignmentsToCreate = [for roleDefinitionId in roleDefinitionIds: {
  name: guid(managedIdentity.id, resourceGroup().id, resourceGroupId)
  roleDefinitionId: roleDefinitionId
}]

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for roleAssignmentToCreate in roleAssignmentsToCreate: {
  name: roleAssignmentToCreate.name
  scope: resourceGroup()
  properties: {
    description: roleAssignmentDescription
    principalId: managedIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignmentToCreate.roleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}]

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2022-03-01' = {
  name: vmssName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentityName)}': {}
    }
  }
  sku: {
    name: skuName
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadWrite'
          createOption: osDiskCreateOption
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}-nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: subnetResourceId
                    }
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'CustomScriptExtension'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.10'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  scriptUri
                ]
                commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ps1.ps1'
                // managedIdentity: {
                //   clientId: managedIdentityClientId
                // }
              }
              protectedSettings: {
                managedIdentity: {
                  clientId: managedIdentityClientId
                }
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    managedIdentity
    roleAssignment
  ]
}

output managedIdentityResourceId string = managedIdentity.id
output managedIdentityClientId string = managedIdentity.properties.clientId
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

output vmssId string = vmss.id
output vmssNameOutput string = vmss.name
