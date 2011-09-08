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

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += Dir["#{Rails.root}/app/controllers/**/**"]
    config.autoload_paths += Dir["#{Rails.root}/app/models/**/**"]
    config.autoload_paths += Dir["#{Rails.root}/app/services/**/**"]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    $log_path = "#{Rails.root}/log/#{Rails.env}.log" if $log_path.nil?
    config.paths.log = $log_path
    config.logger = Logger.new($log_path)
    config.logger.level = Logger.const_get(config.log_level.to_s.upcase)
    config.logger.formatter = Logger::Formatter.new

    # Start AMQP after rails loads:
    config.after_initialize do
      Thread.new { EM.run { } }

      EM.error_handler do |e|
        puts "Error raised during event loop: #{e.message}"
      end

      require 'amqp'
      amqp_yaml = YAML.load_file "#{Rails.root}/config/amqp.yml"
      $amqp_config = amqp_yaml[Rails.env || 'development']
      $amqp_config.symbolize_keys!
      AMQP.start $amqp_config

      ::Application.all.each(&:bind_queue) rescue nil
      ::Channel.all.each(&:bind_queue) rescue nil
    end
  end

  ActionMailer::Base.delivery_method = :sendmail

  # Twitter OAuth configuration
  if File.exists? "#{Rails.root}/config/twitter_oauth_consumer.yml"
    TwitterConsumerConfig = YAML.load_file "#{Rails.root}/config/twitter_oauth_consumer.yml"
  else
    TwitterConsumerConfig = nil
  end

  # Disable account creation from UI
  AccountCreationDisabled = false
end
