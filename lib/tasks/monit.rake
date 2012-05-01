namespace :monit do

  module Monit

    private

    def generate_config(services)
      configs = []

      services.each do |service, script_config|
        if service.is_a?(Hash)
          configs << working_group_configs(service)
        else
          configs << service_config(service, script_config)
        end
      end
      configs.flatten
    end

    def working_group_configs(service)
      configs = []
      service_name = service.keys.first
      service_names = {}
      service[service_name].each do |working_group, num_instances|
        num_instances.times do |instance_id|
          service_names["#{service_name}_#{working_group}_#{instance_id + 1}"] = {
            :script_name => service_name,
            :working_group => working_group,
            :instance_id => instance_id + 1
          }
        end
      end

      configs << generate_config(service_names)
    end

    def service_config(service, script_config)
      script_options = []
      if script_config
        script_name = script_config[:script_name]
        script_options << script_config[:working_group]
        script_options << script_config[:instance_id]
      else
        script_name = service
      end

      rails_env = Rails.env
      root_dir = Rails.root
      current_user = ENV['USER']

      script_args = "#{rails_env} #{script_options.join(' ')}".strip

      full_script_name = "#{script_name}_daemon"
      pid_name = full_script_name
      pid_name += ".#{script_options.join('.')}." unless script_options.empty?

      "check process nuntium_#{service}
        with pidfile #{root_dir}/tmp/pids/#{pid_name}.pid
        start \"/bin/su - #{current_user} -c '#{root_dir}/script/nuntium_service.sh #{full_script_name}_ctl.rb start #{script_args}'\"
        stop \"/bin/su - #{current_user} -c '#{root_dir}/script/nuntium_service.sh #{full_script_name}_ctl.rb stop #{script_args}'\"
        group nuntium"
    end
  end

  desc "Creates the monit configuration for your environment"
  task :generate => :environment do
    include Monit

    services = YAML.load_file(File.join(Rails.root, 'config', 'monit_services.yml'))

    monit_config = generate_config(services).join("\n\n")

    monit_file = "#{Rails.root}/nuntium"

    File.open(monit_file, 'w') { |file| file.write(monit_config) }
    puts "wrote monit config for #{Rails.env} environment to #{monit_file}"
  end
end
