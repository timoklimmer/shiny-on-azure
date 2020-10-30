# use Ubuntu 18.04 as starting point
FROM ubuntu:18.04

# give our new image a name and version
LABEL Name=useyourownacrname.azurecr.io/our-r-base
LABEL Version=1.0.0

# create a custom user to run our app later
ARG HOST_USER_UID=1000
ARG HOST_USER_GID=1000
RUN groupadd -g $HOST_USER_GID appuser \                
    && useradd -l -u $HOST_USER_UID -g $HOST_USER_GID appuser

# set the bash shell as default
# note: this is required. if not set, we cannot "run interactive" the image
CMD /bin/bash

# let Ubuntu know that we cannot use an interactive frontend during Docker image build
ARG DEBIAN_FRONTEND=noninteractive

# update Ubuntu's package information
RUN apt-get update -y

# install some basic packages needed later
RUN apt-get install build-essential libcurl4-gnutls-dev libxml2-dev libssl-dev unzip curl apt-transport-https unixodbc \
    unixodbc-dev -y

# install Microsoft R Open (with MKL)
# notes: - see https://mran.microsoft.com/download for newest versions
#        - changing owner at end to avoid issues with UID/GID renaming, see https://circleci.com/docs/2.0/high-uid-error
RUN apt-get install wget -y \
    && wget https://mran.blob.core.windows.net/install/mro/4.0.2/Ubuntu/microsoft-r-open-4.0.2.tar.gz \
    && tar -xf microsoft-r-open-4.0.2.tar.gz \
    && ./microsoft-r-open/install.sh -a -u \
    && rm microsoft-r-open-4.0.2.tar.gz \
    && rm -rf /microsoft-r-open/logs \
    && chown -R root:root /microsoft-r-open

# install ODBC driver for SQL Server
# note: don't forget to update the URL below for the right OS version in case the OS version is changed
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update -y \
    && ACCEPT_EULA=Y apt-get install msodbcsql17 -y

# install additional packages
# notes: - see Dockerfile reference for copying files/directories into the image in case you want
#          to add your own packages which are not on CRAN
#        - re-install of curl/httr to fix a bug with devtools's package installation feature
RUN Rscript -e "install.packages(c('curl', 'httr', 'devtools', 'jsonlite', 'data.table', 'RODBC', 'shiny'))" \
    && rm -rf /tmp/*