namespace :clients do

  desc "Registers a client application in Nuntium or returns an existing one with the same name"
  task :register => :environment do

    %w(NUNTIUM_URL NUNTIUM_ACCOUNT_NAME NUNTIUM_ACCOUNT_PASS NUNTIUM_APP_NAME NUNTIUM_APP_PASS NUNTIUM_APP_INTERFACE).each do |param|
      raise "Environment variable #{param} is required" if ENV[param].blank?
    end

    account_name = ENV['NUNTIUM_ACCOUNT_NAME']
    account_pass = ENV['NUNTIUM_ACCOUNT_PASS']

    nuntium_url = ENV["NUNTIUM_URL"]
    nuntium_env = ENV["NUNTIUM_ENV"]

    name = ENV['NUNTIUM_APP_NAME']
    password = ENV['NUNTIUM_APP_PASS']
    interface = ENV['NUNTIUM_APP_INTERFACE']
    interface_url = ENV['NUNTIUM_APP_INTERFACE_URL']
    interface_user = ENV['NUNTIUM_APP_INTERFACE_USER']
    interface_password = ENV['NUNTIUM_APP_INTERFACE_PASS']

    account = Account.where(name: account_name).first ||\
      Account.create!(name: account_name, password: account_pass, max_tries: 3)

    application = account.applications.where(name: name).first ||\
      Application.create!(account: account,
        name: name,
        password: password,
        interface: interface.downcase,
        interface_url: interface_url,
        interface_user: interface_user,
        interface_password: interface_password)

    output = {
      "url" => nuntium_url,
      "account" => account_name,
      "password" => account_pass,
      "application" => name,
      "interface_user" => interface_user,
      "interface_pass" => interface_password
    }

    output = { nuntium_env => output } unless nuntium_env.blank?

    puts YAML.dump(output)

  end

end
