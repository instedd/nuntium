# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(assets: %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Nuntium
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += Dir["#{Rails.root}/app/controllers/**/**"].select {|x| !x.end_with? '.rb'}
    config.autoload_paths += Dir["#{Rails.root}/app/models/**/**"].select {|x| !x.end_with? '.rb'}
    config.autoload_paths += Dir["#{Rails.root}/app/services/**/**"].select {|x| !x.end_with? '.rb'}

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

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    $log_path = "#{Rails.root}/log/#{Rails.env}.log" if $log_path.nil?
    config.paths['log'] = $log_path
    config.logger = Logger.new($log_path)
    config.logger.level = Logger.const_get(config.log_level.to_s.upcase)
    config.logger.formatter = Logger::Formatter.new

    # Start AMQP after rails loads:
    config.after_initialize do
      Thread.new { EM.run { } }
      sleep 0.1 until EM.reactor_running?

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

      # Twitter OAuth configuration
      if File.exists? "#{Rails.root}/config/twitter_oauth_consumer.yml"
        ::Nuntium::TwitterConsumerConfig = YAML.load_file "#{Rails.root}/config/twitter_oauth_consumer.yml"
      elsif (TwitterChannel.exists? rescue nil)
        error = "Error: missing '#{Rails.root}/config/twitter_oauth_consumer.yml' for twitter channels"
        Rails.logger.error error
        puts error
        exit 1
      else
        ::Nuntium::TwitterConsumerConfig = nil
      end
    end
  end

  ActionMailer::Base.delivery_method = :sendmail


  # Disable account creation from UI
  AccountCreationDisabled = false
end
