# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  config.load_paths += Dir["#{RAILS_ROOT}/app/controllers/**/**"] 
  config.load_paths += Dir["#{RAILS_ROOT}/app/models/**/**"]
  config.load_paths += Dir["#{RAILS_ROOT}/app/services/**/**"] 

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "mocha"
  config.gem "sqlite3-ruby", :lib => "sqlite3"
  config.gem 'collectiveidea-delayed_job', :lib => 'delayed_job', :source => 'http://gems.github.com'
  config.gem 'test-unit', :lib => 'test/unit'
  config.gem "thoughtbot-shoulda", :lib => "shoulda", :source => "http://gems.github.com"
  config.gem "tmail"
  config.gem 'mislav-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com'
  config.gem "guid"
  config.gem 'twitter', :version => '0.6.15'  
  config.gem 'ruby-smpp', :lib => 'smpp', :version => '0.2.1'
  config.gem "eventmachine"
  config.gem 'amqp'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :some_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
    
  $log_path = "#{RAILS_ROOT}/log/#{ENV['RAILS_ENV']}.log" if $log_path.nil?
  
  if RUBY_PLATFORM.include?('mswin')
    require 'nuntium_logger'
    config.logger = NuntiumLogger.new $log_path, 'rails'
  else
    config.log_path = $log_path
    config.logger = Logger.new($log_path)
    config.logger.formatter = Logger::Formatter.new
  end
  
  # Start AMQP after rails loads:
  config.after_initialize {
    Thread.new { EM.run {} }
  
    require 'amqp'
    AMQP.start do
      MQ.prefetch 100
    end
  }
  
end

# Twitter OAuth configuration
if File.exists?(Rails.root + 'config/twitter_oauth_consumer.yml')
  TwitterConsumerConfig = YAML.load(File.read(Rails.root + 'config/twitter_oauth_consumer.yml'))
else
  TwitterConsumerConfig = nil
end

# Disable application creation from UI
ApplicationCreationDisabled = false

# Include extensions
require 'string'
require 'delayed/job'
