@description('The name of the virtual machine scale set.')
param vmssName string

@description('The location where the resources will be deployed.')
param location string = resourceGroup().location

@description('The ID of the managed image to use for the VMSS.')
param imageId string

@description('The admin username for the VM instances.')
param adminUsername string

@secure()
@description('The admin password for the VM instances.')
param adminPassword string

@description('The size of the VMs in the scale set.')
param vmSize string = 'Standard_DS1_v2'

@description('The subnet ID to which the VMSS instances will be connected.')
param subnetId string


resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2021-04-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: 2
  }
  properties: {
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          id: imageId
        }
        osDisk: {
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
          createOption: 'FromImage'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nicConfig'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipConfig'
                  properties: {
                    subnet: {
                      id: subnetId
                    }
                  }
                }
              ]
            }
          }
        ]
      }
    }
    upgradePolicy: {
      mode: 'Manual'
    }
  }
}