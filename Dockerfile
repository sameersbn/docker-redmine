FROM ubuntu:12.04
MAINTAINER sameer@damagehead.com

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list
RUN apt-get update && apt-get upgrade -y && apt-get clean # 20130925

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_LOCK_DIR /var/run/lock/apache2
ENV APACHE_RUN_DIR /var/run/apache2

RUN apt-get install -y unzip wget apache2-mpm-prefork imagemagick mysql-server \
      subversion git cvs bzr && apt-get clean

RUN apt-get install -y gcc make libcurl4-openssl-dev libssl-dev \
      apache2-prefork-dev libapr1-dev libaprutil1-dev \
      libmagickcore-dev libmagickwand-dev libmysqlclient-dev \
      libxslt1-dev libffi-dev libyaml-dev zlib1g-dev libzlib-ruby && apt-get clean

RUN wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p448.tar.gz -O - | tar -zxf - -C /tmp/ && \
    cd /tmp/ruby-1.9.3-p448/ && ./configure --enable-pthread --prefix=/usr && make && make install && \
    cd /tmp/ruby-1.9.3-p448/ext/openssl/ && ruby extconf.rb && make && make install && \
    cd /tmp/ruby-1.9.3-p448/ext/zlib && ruby extconf.rb && make && make install && cd /tmp \
    rm -rf /tmp/ruby-1.9.3-p448 && gem install --no-ri --no-rdoc bundler mysql2

RUN apt-get install -y sudo supervisor logrotate && apt-get clean

ADD resources/ /redmine/
RUN chmod 755 /redmine/redmine /redmine/setup/install && sync && /redmine/setup/install

EXPOSE 80

ENTRYPOINT ["/redmine/redmine"]
CMD ["start"]
