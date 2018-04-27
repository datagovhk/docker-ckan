FROM debian:jessie

# Define environment variables
ENV CKAN_VERSION 2.7.3

ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/venv
ENV CKAN_CONFIG /etc/ckan
ENV CKAN_STORAGE_PATH /var/lib/ckan

ENV CKAN_SITE_URL http://localhost:5000

# Install required system packages
RUN apt-get -q -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade && \
    apt-get -q -y install python-dev \
                          python-pip \
                          python-virtualenv \
                          python-wheel \
                          libpq-dev \
                          libxml2-dev \
                          libxslt-dev \
                          libgeos-dev \
                          libssl-dev \
                          libffi-dev \
                          postgresql-client \
                          build-essential \
                          git-core \
                          vim \
                          wget \
                          && \
    apt-get -q clean && \
    rm -rf /var/lib/apt/lists/*

# create CKAN user
RUN useradd -r -u 900 -m -d $CKAN_HOME -s /bin/false ckan

# Set up virtual environment
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH && \
    virtualenv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip /usr/local/bin/ckan-pip && \
    ln -s $CKAN_VENV/bin/paster /usr/local/bin/ckan-paster

# Clone CKAN source from GitHub
RUN git clone --branch ckan-$CKAN_VERSION --depth 1 https://github.com/ckan/ckan.git $CKAN_VENV/src/ckan/

# Set up CKAN
RUN ckan-pip install --upgrade pip && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirement-setuptools.txt && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirements.txt && \
    ckan-pip install -e $CKAN_VENV/src/ckan/ && \
    ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/ckan-entrypoint.sh /ckan-entrypoint.sh && \
    chmod +x /ckan-entrypoint.sh && \
    chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH

# TMP-BUGFIX https://github.com/ckan/ckan/issues/3388
# RUN ckan-pip install --upgrade -r $CKAN_VENV/src/ckan/dev-requirements.txt
# TMP-BUGFIX https://github.com/ckan/ckan/issues/3594
# RUN ckan-pip install --upgrade urllib3

ENTRYPOINT ["/ckan-entrypoint.sh"]

# Volumes
# VOLUME ["/etc/ckan/default"]
# VOLUME ["/var/lib/ckan"]

USER ckan
EXPOSE 5000
CMD ["ckan-paster", "serve", "/etc/ckan/default/ckan.ini"]
