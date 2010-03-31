task :environment

namespace :rabbit do
  desc "Reset the entire rabbit-mq server"
  task :reset do
    `sudo rabbitmqctl stop_app`
    `sudo rabbitmqctl reset`
    `sudo rabbitmqctl start_app`
  end
  
  desc "Creates the user and vhost for the current environment configuration"
  task :prepare => :environment do
    `sudo rabbitmqctl add_user #{$amqp_config[:user]} #{$amqp_config[:pass]}`
    `sudo rabbitmqctl add_vhost #{$amqp_config[:vhost]}`
    `sudo rabbitmqctl set_permissions -p #{$amqp_config[:vhost]} #{$amqp_config[:user]} ".*" ".*" ".*"`
  end
end
