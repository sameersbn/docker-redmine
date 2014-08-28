FROM sameersbn/ubuntu:14.04.20140818
MAINTAINER sameer@damagehead.com

RUN add-apt-repository -y ppa:brightbox/ruby-ng \
 && add-apt-repository -y ppa:nginx/stable \
 && apt-get update \
 && apt-get install -y make imagemagick nginx mysql-server memcached \
      subversion git cvs bzr ruby2.1 ruby2.1-dev libcurl4-openssl-dev libssl-dev \
      libmagickcore-dev libmagickwand-dev libmysqlclient-dev libpq-dev \
      libxslt1-dev libffi-dev libyaml-dev zlib1g-dev \
 && gem install --no-ri --no-rdoc bundler \
 && rm -rf /var/lib/apt/lists/* # 20140818

ADD assets/setup/ /app/setup/
RUN chmod 755 /app/setup/install
RUN /app/setup/install

ADD assets/config/ /app/setup/config/
ADD assets/init /app/init
RUN chmod 755 /app/init

EXPOSE 80

# Remove Predefined  Volume Instruction 
# if a user whants a Volume he can start it with that option else you force all users to have
# If you Create A Volume and a user isn't aware of that it can leave volumes on disk if you don do
# docker rm -v containerid
#VOLUME ["/home/redmine/data"]

ENTRYPOINT ["/app/init"]
CMD ["app:start"]
