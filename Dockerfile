FROM ubuntu:12.04
MAINTAINER sameer@damagehead.com

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list
RUN apt-get update # 20140310

# essentials
RUN apt-get install -y vim curl wget sudo net-tools pwgen && \
	apt-get install -y logrotate supervisor openssh-server && \
	apt-get clean

# build tools
RUN apt-get install -y gcc make && apt-get clean

RUN apt-get install -y unzip imagemagick sqlite3 \
      memcached subversion git cvs bzr && apt-get clean

RUN apt-get install -y libcurl4-openssl-dev libssl-dev \
      libapr1-dev libaprutil1-dev \
      libmagickcore-dev libmagickwand-dev libmysqlclient-dev \
      libxslt1-dev libffi-dev libyaml-dev zlib1g-dev libzlib-ruby && apt-get clean

RUN wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p484.tar.gz -O - | tar -zxf - -C /tmp/ && \
    cd /tmp/ruby-1.9.3-p484/ && ./configure --enable-pthread --prefix=/usr && make && make install && \
    cd /tmp/ruby-1.9.3-p484/ext/openssl/ && ruby extconf.rb && make && make install && \
    cd /tmp/ruby-1.9.3-p484/ext/zlib && ruby extconf.rb && make && make install && cd /tmp \
    rm -rf /tmp/ruby-1.9.3-p484 && gem install --no-ri --no-rdoc bundler mysql2 && \
    gem install --no-ri --no-rdoc activerecord-postgresql-adapter && \
    gem install --no-ri --no-rdoc sqlite3

ADD assets/ /redmine/
RUN chmod 755 /redmine/init /redmine/setup/install && /redmine/setup/install

RUN gem install --no-ri --no-rdoc unicorn

ADD authorized_keys /root/.ssh/
RUN mv /redmine/.vimrc /redmine/.bash_aliases /root/
RUN chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys && chown root:root -R /root

EXPOSE 9000

ENTRYPOINT ["/redmine/init"]
CMD ["app:start"]
