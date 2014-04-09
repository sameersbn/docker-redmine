FROM ubuntu:12.04
MAINTAINER sameer@damagehead.com
ENV DEBIAN_FRONTEND noninteractive

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list
RUN apt-get update # 20140409

# Fix some issues with APT packages.
# See https://github.com/dotcloud/docker/issues/1024
RUN dpkg-divert --local --rename --add /sbin/initctl && \
		ln -sf /bin/true /sbin/initctl

# essentials
RUN apt-get install -y vim curl wget sudo net-tools pwgen unzip \
			logrotate supervisor openssh-server && apt-get clean

# build tools
RUN apt-get install -y gcc make && apt-get clean

# image specific
RUN apt-get install -y apache2-mpm-prefork imagemagick mysql-server \
      memcached subversion git cvs bzr ruby1.9.1 \
      ruby1.9.1-dev libcurl4-openssl-dev libssl-dev \
      apache2-prefork-dev libapr1-dev libaprutil1-dev \
      libmagickcore-dev libmagickwand-dev libmysqlclient-dev \
      libxslt1-dev libffi-dev libyaml-dev zlib1g-dev libzlib-ruby && \
    apt-get clean && \
    gem install --no-ri --no-rdoc bundler mysql2 && \
    gem install --no-ri --no-rdoc passenger -v 3.0.21 && \
    passenger-install-apache2-module --auto

ADD assets/ /redmine/
RUN mv /redmine/.vimrc /redmine/.bash_aliases /root/
RUN chmod 755 /redmine/init /redmine/setup/install && /redmine/setup/install

ADD authorized_keys /root/.ssh/
RUN chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys && chown root:root -R /root/.ssh

EXPOSE 22
EXPOSE 80

ENTRYPOINT ["/redmine/init"]
CMD ["app:start"]
