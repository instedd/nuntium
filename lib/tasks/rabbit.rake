task :environment

namespace :rabbit do
  desc "Reset the entire rabbit-mq server"
  task :reset do
    `rabbitmqctl stop_app`
    `rabbitmqctl reset`
    `rabbitmqctl start_app`
  end

  desc "Creates the user and vhost for the current environment configuration"
  task :prepare do
    amqp_yaml = YAML.load_file "#{Rails.root}/config/amqp.yml"
    $amqp_config = amqp_yaml[Rails.env || 'development']
    $amqp_config.symbolize_keys!

    `rabbitmqctl add_user #{$amqp_config[:user]} #{$amqp_config[:pass]}`
    `rabbitmqctl add_vhost #{$amqp_config[:vhost]}`
    `rabbitmqctl set_permissions -p #{$amqp_config[:vhost]} #{$amqp_config[:user]} ".*" ".*" ".*"`
  end
end
