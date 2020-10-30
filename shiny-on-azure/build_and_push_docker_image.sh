#!/bin/bash

# note: as an alternative, if docker is not available on your machine,
#       use the "az acr build" command to build the docker image in Azure directly

echo "Building docker image..."
docker build -t useyourownacrname.azurecr.io/shiny-example:latest .

echo "Pushing docker image to Azure..."
az acr login --name useyourownacrname
docker push useyourownacrname.azurecr.io/shiny-example:latest