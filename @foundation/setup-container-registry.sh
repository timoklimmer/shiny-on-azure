#!/bin/bash

# Create a Container Registry in Azure

# configuration
RESOURCE_GROUP=useyourownrgname
LOCATION=westeurope
ACR_REGISTRY_NAME=useyourownacrname
ACR_SKU=Basic
ACR_ADMIN_ENABLED=true

# say hello
echo "Setting up Azure Container Registry..."
echo "RESOURCE_GROUP           : $RESOURCE_GROUP"
echo "LOCATION                 : $LOCATION"
echo "ACR_REGISTRY_NAME        : $ACR_REGISTRY_NAME"
echo "ACR_SKU                  : $ACR_SKU"
echo "ACR_ADMIN_ENABLED        : $ACR_ADMIN_ENABLED"
echo ""

# create resource group
echo "Creating resource group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# create container registry
echo "Creating container registry..."
az acr create \
    --name $ACR_REGISTRY_NAME \
    --resource-group $RESOURCE_GROUP \
    --sku $ACR_SKU \
    --admin-enabled $ACR_ADMIN_ENABLED
echo ""

echo "Done."
echo "Please note that it can take a few minutes until the registry is available for login."
