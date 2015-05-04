FROM sameersbn/ubuntu:14.04.20150504
MAINTAINER sameer@damagehead.com

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
 && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv 80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6 \
 && echo "deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu trusty main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
 && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" >> /etc/apt/sources.list \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
 && apt-get update \
 && apt-get install -y supervisor logrotate nginx mysql-client postgresql-client \
      imagemagick subversion git cvs bzr mercurial rsync ruby2.1 locales openssh-client \
      gcc g++ make patch pkg-config ruby2.1-dev libc6-dev zlib1g-dev libxml2-dev \
      libmysqlclient18 libpq5 libyaml-0-2 libcurl3 libssl1.0.0 \
      libxslt1.1 libffi6 zlib1g gsfonts \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && gem install --no-document bundler \
 && rm -rf /var/lib/apt/lists/* # 20150504

ADD assets/setup/ /app/setup/
RUN chmod 755 /app/setup/install
RUN /app/setup/install

ADD assets/config/ /app/setup/config/
ADD assets/init /app/init
RUN chmod 755 /app/init

EXPOSE 80
EXPOSE 443

VOLUME ["/home/redmine/data"]
VOLUME ["/var/log/redmine"]

WORKDIR /home/redmine/redmine
ENTRYPOINT ["/app/init"]
CMD ["app:start"]
