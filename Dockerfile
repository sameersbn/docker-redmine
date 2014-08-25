FROM sameersbn/ubuntu:12.04.20140818
MAINTAINER sameer@damagehead.com

RUN add-apt-repository -y ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get install -y make imagemagick nginx \
      mysql-server memcached subversion git cvs bzr ruby2.1 \
      ruby2.1-dev libcurl4-openssl-dev libssl-dev \
      libmagickcore-dev libmagickwand-dev libmysqlclient-dev libpq-dev \
      libxslt1-dev libffi-dev libyaml-dev zlib1g-dev libzlib-ruby && \
    gem install --no-ri --no-rdoc bundler && \
    rm -rf /var/lib/apt/lists/* # 20140818

ADD assets/setup/ /app/setup/
RUN chmod 755 /app/setup/install
RUN /app/setup/install

ADD assets/config/ /app/setup/config/
ADD assets/init /app/init
RUN chmod 755 /app/init

EXPOSE 80
EXPOSE 443

VOLUME ["/home/redmine/data"]
ENTRYPOINT ["/app/init"]

CMD ["app:start"]
