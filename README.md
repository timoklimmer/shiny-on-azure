# Shiny on Azure

A sample that shows how to build a Shiny app on Docker and deploy the app on Azure Web Apps.

Once deployed, the web app will be secured by Azure Active Directory and will automatically update whenever a new image is pushed to the container registry.

The code provided here should easily be adoptable for other frameworks such as dash etc.

IMPORTANT: At some places, names need to be unique across Azure. To avoid conflicts, use a find & replace tool of your choice and replace the following strings with your own.

- useyourownrgname -> name of your resource group
- useyourownacrname -> name of your Azure container registry
- useyourownplanname -> name of your App Service plan
- useyourownwebappname -> name of your web app (will be part of the link)
- useyourownfriendlywebappname -> friendly name of your web app (can include blank characters etc.)
- useyourownlocation -> location where the solution will live, eg. westeurope.

As always, artifacts are provided "as is". Feel free to reuse but don't blame me if things go wrong.

Enjoy!
