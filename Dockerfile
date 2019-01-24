FROM instedd/nginx-rails:1.9

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
RUN bundle install --jobs 3 --deployment --without development test

ENV RAILS_LOG_TO_STDOUT true

# Install the application
ADD . /app

# Link Twitter config file
RUN ln -s /run/secrets/twitter_oauth_consumer.yml /app/config

# Generate version file
RUN if [ -d .git ]; then git describe --always > VERSION; fi

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=production

# Add config files
ADD docker/runit-web-run /etc/service/web/run
ADD docker/database.yml /app/config/database.yml
ADD docker/amqp.yml /app/config/amqp.yml
ADD docker/migrate /app/migrate
