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

require "openid"
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require 'openid/store/filesystem'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nuntium
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # TODO AR RAILS4 move this where?
    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += Dir["#{Rails.root}/app/controllers/**/**"].select {|x| !x.end_with? '.rb'}
    config.autoload_paths += Dir["#{Rails.root}/app/models/**/**"].select {|x| !x.end_with? '.rb'}
    config.autoload_paths += Dir["#{Rails.root}/app/services/**/**"].select {|x| !x.end_with? '.rb'}

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    $log_path = "#{Rails.root}/log/#{Rails.env}.log" if $log_path.nil?
    config.paths['log'] = $log_path
    config.logger = Logger.new($log_path)
    config.logger.level = Logger.const_get(config.log_level.to_s.upcase)
    config.logger.formatter = Logger::Formatter.new

    config.i18n.enforce_available_locales = false

    SettingsPath = "#{::Rails.root.to_s}/config/settings.yml"

    if FileTest.exists?(SettingsPath)
      settings = YAML.load_file(SettingsPath)[::Rails.env].with_indifferent_access
      config.action_mailer.default_url_options = { :host => settings[:host_name],
                                                   :protocol => settings[:protocol] }
    end

    # Start AMQP after rails loads:
    config.after_initialize do
      amqp_yaml = YAML.load_file "#{Rails.root}/config/amqp.yml"
      $amqp_config = amqp_yaml[Rails.env || 'development']
      $amqp_config.symbolize_keys!

      Queues.init

      # TODO(ggiraldez): This should probably check for errors instead of
      # ignoring the exceptions
      ::Application.all.each(&:bind_queue) rescue nil
      ::Channel.all.each(&:bind_queue) rescue nil

      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          if forked
            Queues.init
          end
        end
      end

      # Twitter OAuth configuration
      if File.exists? "#{Rails.root}/config/twitter_oauth_consumer.yml"
        ::Nuntium::TwitterConsumerConfig = YAML.load_file "#{Rails.root}/config/twitter_oauth_consumer.yml"
      elsif (TwitterChannel.exists? rescue nil)
        error = "Error: missing '#{Rails.root}/config/twitter_oauth_consumer.yml' for twitter channels"
        Rails.logger.error error
        puts error
        exit 1
      else
        ::Nuntium::TwitterConsumerConfig = {}
      end
    end
  end

  ActionMailer::Base.delivery_method = :sendmail

  # Disable account creation from UI
  AccountCreationDisabled = false
end
