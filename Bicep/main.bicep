param vmssName string = 'myVMSS'
param location string = 'East US'
param imageId string
param adminUsername string = 'azureuser'
@secure()
param adminPassword string
param subnetId string

var publisher = 'MicrosoftWindowsServer'
var offer = 'WindowsServer'
var sku = '2022-Datacenter'
var version = 'latest'

resource vmImage 'Microsoft.Compute/images@2021-04-01' existing = {
  name: '${publisher}:${offer}:${sku}:${version}'
}

module vmss './vmss.bicep' = {
  name: 'vmssDeployment'
  params: {
    vmssName: vmssName
    location: location
    imageId: imageId
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: 'Standard_DS1_v2'
    subnetId: subnetId
  }
}

