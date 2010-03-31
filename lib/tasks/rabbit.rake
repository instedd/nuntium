task :environment

namespace :rabbit do
  desc "Reset the entire rabbit-mq server"
  task :reset do
    `sudo rabbitmqctl stop_app`
    `sudo rabbitmqctl reset`
    `sudo rabbitmqctl start_app`
  end
  
  desc "Creates the vhost for the current environment configuration"
  task :add_vhost => :environment do
    `sudo rabbitmqctl add_vhost #{$amqp_config[:vhost]}`
  end
end
