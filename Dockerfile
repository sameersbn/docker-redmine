FROM sameersbn/ubuntu:12.04.20140519
MAINTAINER sameer@damagehead.com

RUN apt-get update && \
		apt-get install -y make imagemagick nginx \
      mysql-server memcached subversion git cvs bzr ruby1.9.1 \
      ruby1.9.1-dev libcurl4-openssl-dev libssl-dev \
      libmagickcore-dev libmagickwand-dev libmysqlclient-dev libpq-dev \
      libxslt1-dev libffi-dev libyaml-dev zlib1g-dev libzlib-ruby && \
    gem install --no-ri --no-rdoc bundler && \
    apt-get clean # 20140519

ADD assets/setup/ /redmine/setup/
RUN chmod 755 /redmine/setup/install
RUN /redmine/setup/install

ADD assets/config/ /redmine/setup/config/
ADD assets/init /redmine/init
RUN chmod 755 /redmine/init

ADD authorized_keys /root/.ssh/

EXPOSE 80

VOLUME ["/redmine/files"]

ENTRYPOINT ["/redmine/init"]
CMD ["app:start"]
