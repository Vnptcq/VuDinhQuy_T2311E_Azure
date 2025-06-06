#!/bin/bash
dotnet publish -c RELEASE -o publish
zip -r ../publish.zip .

DEPLOY_SC_PATH="../publish.zip" # Path to the zip file containing the web app
RESOURCE_GROUP="opit" # If you use sandbox, you can use a different name
WEBAPP_NAME="opit" # Name of the web app
LOCATION="southeastasia"
APP_SERVICE_PLAN="T2311eappserviceplan" # Name of the App Service Plan
SERVICE_PLAN_PRICE="F1" # Pricing tier for the App Service Plan
RUNTIME="DOTNETCORE|8.0" # Runtime for the web app

SQL_SERVER_NAME="opitsqlserver" # Name of the SQL server
SQL_ADMIN_USER="sqladmin" # Admin username for the SQL server
SQL_ADMIN_PASSWORD="#iojfoifmkr" # Admin password for the SQL server
SQL_DB="opitdb" # Name of the SQL database
# Create a resource group in Azure
az group create --name $RESOURCE_GROUP --location $LOCATION
# Create an App Service Plan
az appservice plan create \
    --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku $SERVICE_PLAN_PRICE \
    --is-linux
# Create a web app in the App Service Plan
az webapp create \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN \
    --runtime $RUNTIME 
# Create database using Azure SQL Database
az sql server fire-wall create \
    --name $SQL_SERVER_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --admin-user $SQL_ADMIN_USER \
    --admin-password $SQL_ADMIN_PASSWORD # Change this to a secure password
# Create a SQL Database in the server
az sql db create \
    --resource-group $RESOURCE_GROUP \
    --server $SQL_SERVER_NAME \
    --name $SQL_DB \
    --service-objective "S0" # Change this to your desired service tier

az webapp config connection-string \
    set --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings "DefaultConnection=Server=tcp:$SQL_SERVER_NAME.database.windows.net,1433;Initial Catalog=$SQL_DB;Persist Security Info=False;User ID=$SQL_ADMIN_USER;Password=$SQL_ADMIN_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" \
    --connection-string-type "SQLAzure"

# Deploy the web app using the zip file
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP --name "opitwebapp" --src ../publish.zip

# Clean up the publish directory
rm -rf publish
# Output the URL of the deployed web app
echo "Web app deployed successfully. You can access it at:"
echo "https://opitwebapp.azurewebsites.net"

# Optionally, you can open the web app in the default browser
if command -v xdg-open > /dev/null; then
    xdg-open "https://opitwebapp.azurewebsites.net"
elif command -v open > /dev/null; then
    open "https://opitwebapp.azurewebsites.net"
else
    echo "Please visit https://opitwebapp.azurewebsites.net in your web browser."
fi # fi is used to close the if statement
# End of deploy.sh