FROM mongo:3.4.19-jessie
USER root
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libzmq3-dev

ADD https://github.com/qtumproject/qtum/releases/download/mainnet-ignition-v0.17.2/qtum-0.17.2-x86_64-linux-gnu.tar.gz /tmp/
RUN tar -xvf /tmp/qtum-*.tar.gz -C /tmp/
RUN cp /tmp/qtum*/bin/*  /usr/local/bin
RUN rm -rf /tmp/qtum*

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Update the repository sources list
RUN apt-get update

################## BEGIN INSTALLATION ######################
# Install MongoDB Following the Instructions at MongoDB Docs
# Ref: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/

# Add the package verification key
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10

# Add MongoDB to the repository sources list
RUN echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list

# Update the repository sources list once more
RUN apt-get update

# Install MongoDB package (.deb)
RUN apt-get install -y mongodb-10gen

# Create the default data directory
RUN mkdir -p /data/db

##################### INSTALLATION END #####################

# Expose the default port
EXPOSE 27017

# Default port to execute the entrypoint (MongoDB)
# CMD ["--port 27017"]

ENV APP_HOME /home/node/app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

RUN npm -g config set user root
RUN npm i -g https://github.com/qtumproject/qtumcore-node.git#master
RUN qtumcore-node create qtumNode
WORKDIR $APP_HOME/qtumNode
RUN qtumcore-node install https://github.com/qtumproject/insight-api.git#master
RUN qtumcore-node install https://github.com/qtumproject/qtum-explorer.git#master

COPY qtumNode/data/qtum.conf ./data/qtum.conf
COPY qtumNode/qtumcore-node.json ./qtumcore-node.json


EXPOSE 8332 3001 28332 13888 13889

CMD service mongod start
ENTRYPOINT qtumcore-node start
