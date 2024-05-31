param vmssName string = 'myVMSS'
param location string = 'East US'
param imageId string
param adminUsername string = 'azureuser'
@secure()
param adminPassword string
param subnetId string


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

