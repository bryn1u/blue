# „Spit that shit!”

az deployment group create --resource-group myResourceGroup --template-file main.bicep --parameters \
  location="westeurope" \
  imageId="/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Compute/images/<image-name>" \
  subscriptionId="<subscription-id>" \
  resourceGroupName="<resource-group>" \
  imageName="<image-name>" \
  scriptUri="https://<your-storage-account>.blob.core.windows.net/scripts/update.sh"


