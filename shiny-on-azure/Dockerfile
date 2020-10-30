# use Ubuntu 18.04 as base image
FROM useyourownacrname.azurecr.io/our-r-base:latest

# give our new image a name and version
LABEL Name=useyourownacrname.azurecr.io/shiny-app:latest
LABEL Version=1.0.0

# deploy and run shiny app
COPY ./shiny-app /shiny-app
RUN chown appuser:appuser -R /shiny-app
WORKDIR /shiny-app
USER appuser
EXPOSE 8080/tcp
ENTRYPOINT Rscript -e "shiny::runApp(appDir='/shiny-app', host='0.0.0.0', port=8080)"