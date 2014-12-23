task :environment

namespace :rabbit do
  desc "Reset the entire rabbit-mq server"
  task :reset do
    `rabbitmqctl stop_app`
    `rabbitmqctl reset`
    `rabbitmqctl start_app`
  end

  # FIXME(ggiraldez): This doesn't work since we try to connect with these
  # credentials at initialization time, ie. before this is executed
  desc "Creates the user and vhost for the current environment configuration"
  task :prepare => :environment do
    `rabbitmqctl add_user #{$amqp_config[:user]} #{$amqp_config[:pass]}`
    `rabbitmqctl add_vhost #{$amqp_config[:vhost]}`
    `rabbitmqctl set_permissions -p #{$amqp_config[:vhost]} #{$amqp_config[:user]} ".*" ".*" ".*"`
  end
end
