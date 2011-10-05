require 'rubygems'
require 'logger'
require 'amqp'
require 'active_record'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/dependencies'
require 'yaml'
require 'em-net-http'

ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
ENV["RAILS_ENV"] ||= "development"

module Rails
  class << self
    def root
      @root ||= File.expand_path '../../../', __FILE__
    end

    def logger
      @logger ||= begin
                    logger = Logger.new(STDOUT.tty? ? STDOUT : $log_path)
                    logger.formatter = Logger::Formatter.new
                    logger
                  end
    end

    def cache
      @cache ||= ActiveSupport::Cache::MemCacheStore.new
    end

    def env
      ENV["RAILS_ENV"]
    end
  end
end

class ActiveRecord::Base
  def logger
    Rails.logger
  end
end

# Autoload models and services
ActiveSupport::Dependencies.autoload_paths += [File.expand_path("../../../app/models", __FILE__)]
ActiveSupport::Dependencies.autoload_paths += [File.expand_path("../../../app/services", __FILE__)]
ActiveSupport::Dependencies.autoload_paths += Dir[File.expand_path("../../../app/models/**/**", __FILE__)].select {|x| !x.end_with? '.rb'}

# Initialize active record
database_yml = YAML.load_file File.expand_path('../../../config/database.yml', __FILE__)
database_yml = database_yml[ENV["RAILS_ENV"]]
ActiveRecord::Base.establish_connection database_yml

# Require initializers
Dir[File.expand_path("../../../config/initializers/**", __FILE__)].each do |file|
  require file
end

# Start EM
Thread.new { EM.run {} }
until EM.reactor_running?
  sleep 0.1
end

EM.error_handler do |e|
  puts "Error raised during event loop: #{e.message}"
  puts e.backtrace
end

# Start RabbitMQ
amqp_yaml = YAML.load_file File.expand_path("../../../config/amqp.yml", __FILE__)
amqp_config = amqp_yaml[ENV["RAILS_ENV"]]
amqp_config.symbolize_keys!
AMQP.start amqp_config

def start_service(log_name)
  $log_path = File.expand_path("../../../log/#{log_name}.log", __FILE__)

  yield
rescue Exception => err
  Rails.logger.error "Daemon failure: #{err} #{err.backtrace}"
end
