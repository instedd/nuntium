FROM instedd/ruby:1.9 AS dev

# we need jessie-backports to support the new Let's Encrypt Root CA
RUN printf "\ndeb [trusted=yes] http://archive.debian.org/debian jessie-backports main" >> /etc/apt/sources.list

# Cleanup expired Let's Encrypt CA (Sept 30, 2021)
RUN sed -i '/^mozilla\/DST_Root_CA_X3/s/^/!/' /etc/ca-certificates.conf && update-ca-certificates -f

RUN apt-get update && \
  curl -sL https://deb.nodesource.com/setup_4.x | bash - && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes nodejs && \
  # I wasn't able to pin-point which packages need to be updated in order for Let's Encrypt new Root CA to work
  # Upgrading every available package does the trick - so we'll go with that, even at the cost of a larger Docker image
  DEBIAN_FRONTEND=noninteractive apt-get upgrade && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Update gem version to one that's compatible with Let's Encrypt new Root CA
RUN gem update --system 1.8.30

WORKDIR /app

FROM dev AS release

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
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
