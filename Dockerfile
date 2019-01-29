FROM ruby:1.9

# Install nodejs
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs && \
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
