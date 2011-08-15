require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Nuntium
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{RAILS_ROOT}/extras )
    config.autoload_paths += Dir["#{Rails.root}/app/controllers/**/**"]
    config.autoload_paths += Dir["#{Rails.root}/app/models/**/**"]
    config.autoload_paths += Dir["#{Rails.root}/app/services/**/**"]

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

    $log_path = "#{Rails.root}/log/#{Rails.env}.log" if $log_path.nil?

    config.paths.log = $log_path
    config.logger = Logger.new($log_path)
    config.logger.level = Logger.const_get(config.log_level.to_s.upcase)
    config.logger.formatter = Logger::Formatter.new

    # Start AMQP after rails loads:
    config.after_initialize {
      Thread.new { EM.run { } }

      EM.error_handler do |e|
        puts "Error raised during event loop: #{e.message}"
      end

      require 'amqp'
      amqp_yaml = YAML.load_file("#{Rails.root}/config/amqp.yml")
      $amqp_config = amqp_yaml[Rails.env || 'development']
      $amqp_config.symbolize_keys!
      AMQP.start($amqp_config)
    }

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
  end

  ActionMailer::Base.delivery_method = :sendmail

  # Twitter OAuth configuration
  if File.exists?(Rails.root + 'config/twitter_oauth_consumer.yml')
    TwitterConsumerConfig = YAML.load(File.read(Rails.root + 'config/twitter_oauth_consumer.yml'))
  else
    TwitterConsumerConfig = nil
  end

  # Disable account creation from UI
  AccountCreationDisabled = false
end
