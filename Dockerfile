FROM sameersbn/ubuntu:12.04.20140418
MAINTAINER sameer@damagehead.com

RUN apt-get update && \
		apt-get install -y make apache2-mpm-prefork imagemagick \
      mysql-server memcached subversion git cvs bzr ruby1.9.1 \
      ruby1.9.1-dev libcurl4-openssl-dev libssl-dev \
      apache2-prefork-dev libapr1-dev libaprutil1-dev \
      libmagickcore-dev libmagickwand-dev libmysqlclient-dev libpq-dev \
      libxslt1-dev libffi-dev libyaml-dev zlib1g-dev libzlib-ruby && \
    gem install --no-ri --no-rdoc bundler mysql2 pg && \
    gem install --no-ri --no-rdoc passenger -v 3.0.21 && \
    passenger-install-apache2-module --auto && \
    apt-get clean # 20140418

ADD assets/ /redmine/
RUN chmod 755 /redmine/init /redmine/setup/install
RUN /redmine/setup/install

ADD authorized_keys /root/.ssh/

EXPOSE 80

VOLUME ["/redmine/files"]

ENTRYPOINT ["/redmine/init"]
CMD ["app:start"]
