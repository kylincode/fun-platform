FROM ubuntu:16.04

# Install system dependencies
# Removing the package lists after installation is a good practice
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential curl g++ gcc gettext gfortran git git-core \
    graphviz graphviz-dev language-pack-en libffi-dev libfreetype6-dev libgeos-dev \
    libjpeg8-dev liblapack-dev libmysqlclient-dev libpng12-dev libxml2-dev \
    libxmlsec1-dev libxslt1-dev nodejs npm ntp pkg-config python-apt python-dev \
    python-pip software-properties-common swig \
    python-software-properties \
    libatlas-dev libblas-dev locales python-scipy python-numpy \
    libjpeg-dev zlib1g-dev libxslt-dev \
    yui-compressor libgraphviz-dev graphviz-dev \
    libreadline6 libreadline6-dev nodejs coffeescript mysql-client \
    libgeos-ruby1.8 lynx-cur libxmlsec1-dev \
    wget libssl-dev tzdata vim && \
    rm -rf /var/lib/apt/lists/*

# Set container timezone and related timezones database and DST rules
# See https://serverfault.com/a/856593
ENV TZ 'Etc/UTC'
RUN echo $TZ > /etc/timezone && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN ln -s /usr/bin/nodejs /usr/bin/node
WORKDIR /edx/app/edxapp/edx-platform

# Install Python requirements
# ... adding only targeted requirements files first to benefit from caching
ADD ./src/edx-platform/requirements/edx /edx/app/edxapp/edx-platform/requirements/edx
RUN pip install --src ../src -r requirements/edx/pre.txt && \
    pip install --src ../src -r requirements/edx/github.txt && \
    pip install --src ../src -r requirements/edx/base.txt && \
    pip install --src ../src -r requirements/edx/paver.txt && \
    pip install --src ../src -r requirements/edx/post.txt

# Install Javascript requirements
# ... adding only the package.json file first to benefit from caching
ADD ./src/edx-platform/package.json /edx/app/edxapp/edx-platform/package.json
RUN npm install

# Force the reinstallation of edx-ui-toolkit's dependencies inside its node_modules
# because someone is poking files from there when updating assets.
RUN cd /edx/app/edxapp/edx-platform/node_modules/edx-ui-toolkit && npm install


# Now add the complete project sources
ADD ./src/edx-platform /edx/app/edxapp/edx-platform
# We are building a whitebrand with fun-apps, so add repositories
ADD ./src/fun-apps /edx/app/edxapp/fun-apps
ADD ./src/themes/fun /edx/app/edxapp/themes/fun

# Install fun whitebrand dependecies
RUN pip install --src ../src -r ../fun-apps/requirements/base_wb.txt

# Install the project Python packages
RUN pip install --src ../src -r requirements/edx/local.txt

ADD /config /config

# Configuration files are mounted in "/config"
# Point to them with symbolic links
#RUN ln -sf /config/lms.env.json /edx/app/edxapp/lms.env.json && \
#    ln -sf /config/lms.auth.json /edx/app/edxapp/lms.auth.json && \
#    ln -sf /config/cms.env.json /edx/app/edxapp/cms.env.json && \
#    ln -sf /config/cms.auth.json /edx/app/edxapp/cms.auth.json

# Symlink /config to edx-platform settings folder
RUN ln -sf /config /edx/app/edxapp/edx-platform/lms/envs/fun && \
    ln -sf /config /edx/app/edxapp/edx-platform/cms/envs/fun

# Update assets and collect statics files
RUN NO_PREREQ_INSTALL=1 paver update_assets --settings=fun.docker_build

# Use Gunicorn in production as web server
CMD DJANGO_SETTINGS_MODULE=${SERVICE_VARIANT}.envs.fun.docker_run_${SERVICE_VARIANT} \
    gunicorn --name=${SERVICE_VARIANT} --bind=0.0.0.0:8000 --max-requests=1000 ${SERVICE_VARIANT}.wsgi:application

