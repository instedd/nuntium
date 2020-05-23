FROM ruby:1.9

# ruby:1.9 is based on Debian Jessie, which has been archived now
RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\n" > /etc/apt/sources.list

# Install nodejs (ignoring GPG's signature expiration, since Debian Jessie won't get those updated: https://wiki.debian.org/DebianJessie )
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
WORKDIR /app
RUN bundle install --jobs 3 --deployment --without development test

# Install the application
ADD . /app

# Link Twitter config file
RUN ln -s /run/secrets/twitter_oauth_consumer.yml /app/config

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=production

# Add config files
ADD docker/database.yml /app/config/database.yml
ADD docker/amqp.yml /app/config/amqp.yml
ADD docker/migrate /app/migrate

ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_ENV=production
ENV WEB_BIND_URI=tcp://0.0.0.0:80
ENV PUMA_TAG=nuntium
ENV WEB_PUMA_FLAGS=
EXPOSE 80

CMD exec puma -e $RAILS_ENV -b $WEB_BIND_URI --tag $PUMA_TAG $WEB_PUMA_FLAGS
