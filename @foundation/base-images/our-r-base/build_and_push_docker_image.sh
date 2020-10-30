#!/bin/bash

echo "Building docker image..."
docker build -t useyourownacrname.azurecr.io/our-r-base:latest .

echo "Pushing docker image to Azure..."
az acr login --name useyourownacrname
docker push useyourownacrname.azurecr.io/our-r-base:latest