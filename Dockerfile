FROM debian:jessie

ENV CKAN_VERSION 2.7.3

ENV CKAN_HOME /usr/lib/ckan/default
ENV CKAN_CONFIG /etc/ckan/default
ENV CKAN_STORAGE_PATH /var/lib/ckan

ENV CKAN_SITE_URL http://localhost:5000

# Install required packages
RUN apt-get -q -y update && apt-get -q -y upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y install python-dev \
                                                            python-pip \
                                                            python-virtualenv \
                                                            libpq-dev \
                                                            git-core \
    && apt-get -q clean

# Set up virtual environment
RUN mkdir -p $CKAN_HOME $CKAN_CONFIG $CKAN_STORAGE_PATH
RUN virtualenv $CKAN_HOME
RUN ln -s $CKAN_HOME/bin/pip /usr/local/bin/ckan-pip
RUN ln -s $CKAN_HOME/bin/paster /usr/local/bin/ckan-paster

# Set up requirements
ADD https://raw.githubusercontent.com/ckan/ckan/ckan-$CKAN_VERSION/requirements.txt $CKAN_HOME/src/ckan/
RUN ckan-pip install --upgrade -r $CKAN_HOME/src/ckan/requirements.txt

# TMP-BUGFIX https://github.com/ckan/ckan/issues/3388
ADD https://raw.githubusercontent.com/ckan/ckan/ckan-$CKAN_VERSION/dev-requirements.txt $CKAN_HOME/src/ckan/
RUN ckan-pip install --upgrade -r $CKAN_HOME/src/ckan/dev-requirements.txt

# TMP-BUGFIX https://github.com/ckan/ckan/issues/3594
RUN ckan-pip install --upgrade urllib3

# Set up CKAN
RUN git clone --branch ckan-$CKAN_VERSION --depth 1 https://github.com/ckan/ckan.git $CKAN_HOME/src/ckan/
RUN ckan-pip install -e $CKAN_HOME/src/ckan/
RUN ln -s $CKAN_HOME/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini

# Set up entry point
ADD https://raw.githubusercontent.com/ckan/ckan/ckan-$CKAN_VERSION/contrib/docker/ckan-entrypoint.sh /
RUN chmod +x /ckan-entrypoint.sh
ENTRYPOINT ["/ckan-entrypoint.sh"]

# Volumes
VOLUME ["/etc/ckan/default"]
VOLUME ["/var/lib/ckan"]

EXPOSE 5000
CMD ["ckan-paster", "serve", "/etc/ckan/default/ckan.ini"]
