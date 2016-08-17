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
    rabbitmq_cmd = "rabbitmqctl"
    $amqp_config = amqp_yaml[ENV["TRAVIS"] ? "travis" : (Rails.env || 'development')]
    $amqp_config.symbolize_keys!

    puts `#{rabbitmq_cmd} status`
    `#{rabbitmq_cmd} add_user #{$amqp_config[:user]} #{$amqp_config[:pass]}`
    `#{rabbitmq_cmd} add_vhost #{$amqp_config[:vhost]}`
    `#{rabbitmq_cmd} set_permissions -p #{$amqp_config[:vhost]} #{$amqp_config[:user]} ".*" ".*" ".*"`
  end
end
