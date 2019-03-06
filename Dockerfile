FROM mongo:3.4.19-jessie
USER root
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libzmq3-dev

RUN set -ex \
    && apt-get update \
    && apt-get install -y -qq --no-install-recommends ca-certificates curl wget apt-utils jq
# install qtum binaries
RUN set -ex \
    && echo `curl -s https://api.github.com/repos/qtumproject/qtum/releases/latest | jq -r ".assets[] | select(.name | test(\"x86_64-linux-gnu.tar.gz\")) | .browser_download_url"` > /tmp/qtum_url \
    && QTUM_URL=`cat /tmp/qtum_url` \
    && QTUM_DIST=$(basename $QTUM_URL) \
    && wget -O $QTUM_DIST $QTUM_URL \
	&& tar -xzvf $QTUM_DIST -C /usr/local --strip-components=1 \
	&& rm /tmp/qtum*

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4

RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list
RUN apt-get update
RUN apt-get install -y mongodb-org
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
