# Provision an Azure Web App which bases on a given Docker image.
# Once provisioned, the web app will automatically pick up new images from the container registry.
#
# Written in PowerShell 7.0.3.

# --- configuration
$RESOURCE_GROUP="useyourownrgname"
$LOCATION="useyourownlocation"
$APP_SERVICE_PLAN_NAME="useyourownplannamehere"
$APP_SERVICE_PLAN_SKU="S1"
$APP_SERVICE_PLAN_WORKERS="1"
$WEB_APP_NAME="useyourownwebappname"
$WEB_APP_NAME_FRIENDLY="useyourownfriendlywebappname"
$ACR_REGISTRY="useyourownacrname"
$REGISTRY_USER="$ACR_REGISTRY"
$DOCKER_IMAGE="shiny-example:latest"


# --- say hello
Write-Host "Deploying container to Azure Web App..."
Write-Host "RESOURCE_GROUP           : $RESOURCE_GROUP"
Write-Host "LOCATION                 : $LOCATION"
Write-Host "APP_SERVICE_PLAN_NAME    : $APP_SERVICE_PLAN_NAME"
Write-Host "APP_SERVICE_PLAN_SKU     : $APP_SERVICE_PLAN_SKU"
Write-Host "APP_SERVICE_PLAN_WORKERS : $APP_SERVICE_PLAN_WORKERS"
Write-Host "WEB_APP_NAME             : $WEB_APP_NAME"
Write-Host "WEB_APP_NAME_FRIENDLY    : $WEB_APP_NAME_FRIENDLY"
Write-Host "ACR_REGISTRY             : $ACR_REGISTRY"
Write-Host "REGISTRY_USER            : $REGISTRY_USER"
Write-Host "DOCKER_IMAGE             : $DOCKER_IMAGE"
Write-Host ""


# --- create plan and empty webapp
Write-Host "Creating default web app (incl. app service plan)..."
az appservice plan create `
    --name $APP_SERVICE_PLAN_NAME `
    --resource-group $RESOURCE_GROUP `
    --is-linux -l $LOCATION `
    --sku $APP_SERVICE_PLAN_SKU `
    --number-of-workers $APP_SERVICE_PLAN_WORKERS
az webapp create `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --plan $APP_SERVICE_PLAN_NAME `
    --deployment-container-image-name nginx


# --- enable logging
Write-Host "Enable logging..."
az webapp log config `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --application-logging filesystem `
    --docker-container-logging filesystem `
    --web-server-logging filesystem


# --- setup Azure AD auth
Write-Host "Setting up Azure AD auth..."
Write-Host "--> Registering application and adding credential/secret..."
$web_url = "https://" + $WEB_APP_NAME + ".azurewebsites.net"
$reply_url = $web_url + "/.auth/login/aad/callback"
$ad_app_id = az ad app create `
    --display-name $WEB_APP_NAME_FRIENDLY `
    --identifier-uris $web_url `
    --reply-urls $reply_url `
    --query appId `
    --homepage $web_url
Write-Host "Registered app id: $ad_app_id"
$app_secret = (az ad app credential reset --id $ad_app_id  | ConvertFrom-Json)

Write-Host "--> Giving required permissions to app..."
# MicrosoftGraph OpenId delegated permission
$apiResourceAppId = "00000003-0000-0000-c000-000000000000"
$openIdApiPermission = "37f7f235-527c-4136-accd-4a02d197296e=Scope"
az ad app permission add --id $ad_app_id --api $apiResourceAppId  --api-permissions $openIdApiPermission
#az ad app permission grant --id $ad_app_id --api $apiResourceAppId --expires never

Write-Host "--> Getting issuer URL..."
$metadataurl = (az cloud show | ConvertFrom-Json).endpoints.activeDirectory `
    + "/" + $app_secret.tenant `
    + "/.well-known/openid-configuration"
$metadata = (Invoke-WebRequest -Uri $metadataurl | ConvertFrom-Json)

Write-Host "--> Updating web app to use AzureAD auth..."
az webapp auth update `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --enabled true `
    --action LoginWithAzureActiveDirectory `
    --aad-client-id $app_secret.appId  `
    --aad-client-secret $app_secret.password `
    --aad-token-issuer-url $metadata.issuer `
    --aad-allowed-token-audiences $web_url `
    --allowed-external-redirect-urls $web_url


# --- update the Web App to use our own container
$registry_server_password=(az acr credential show `
    --name $ACR_REGISTRY `
    --resource-group $RESOURCE_GROUP `
    --query passwords[0].value `
    --output tsv `
)
az webapp config container set `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --docker-custom-image-name "$ACR_REGISTRY.azurecr.io/$DOCKER_IMAGE" `
    --docker-registry-server-url "https://$ACR_REGISTRY.azurecr.io" `
    --docker-registry-server-user "$ACR_REGISTRY" `
    --docker-registry-server-password "$registry_server_password"


# --- map web app port to container port (only if container is not listening on port 80)
Write-Host "Map port 8080 -> 80..."
az webapp config appsettings set `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --settings WEBSITES_PORT=8080


# --- enable Continuous Deployment
Write-Host "Enable Continuous Deployment..."
az webapp deployment container config `
    --name $WEB_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --enable-cd true
$CI_CD_URL=( `
    az webapp deployment container show-cd-url `
        --name $WEB_APP_NAME `
        --resource-group $RESOURCE_GROUP `
        --query CI_CD_URL `
        --output tsv
)
az acr webhook create `
    --name $WEB_APP_NAME `
    --registry $ACR_REGISTRY `
    --uri $CI_CD_URL `
    --actions push delete