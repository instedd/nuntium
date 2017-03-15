# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "nuntium.local"

  config.vm.network :forwarded_port, guest: "80", host: "8080", host_ip: "127.0.0.1"
  config.vm.network :public_network, ip: '192.168.1.12'

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "4096"]
  end

  config.vm.provision :shell do |s|
    s.privileged = false
    s.args = [ENV['REVISION'] || "1.9.1"]
    s.inline = <<-SH

    export DEBIAN_FRONTEND=noninteractive

    # Install required packages
    sudo apt-get update
    sudo -E apt-get -y install ruby1.9.3 apache2 git \
      libxml2-dev libxslt1-dev libzmq3-dbg libzmq3-dev libzmq3 mysql-client libmysqlclient-dev nodejs \
      libcurl4-openssl-dev apache2-threaded-dev libapr1-dev libaprutil1-dev libyaml-dev postfix festival curl \
      build-essential pkg-config libncurses5-dev uuid-dev libjansson-dev

    # Install rabbitmq
    # https://www.rabbitmq.com/install-debian.html
    sudo -E apt-get -y install rabbitmq-server

    # Install memcached
    sudo -E apt-get -y install memcached

    # Install bundler
    sudo gem install bundler --no-ri --no-rdoc

    # Install passenger
    sudo gem install rack -v 1.6.4 --no-ri --no-rdoc
    sudo gem install passenger -v 5.0.23 --no-ri --no-rdoc
    sudo passenger-install-apache2-module -a
    sudo sh -c 'passenger-install-apache2-module --snippet > /etc/apache2/mods-available/passenger.load'
    sudo a2enmod passenger

    # Configure apache website for Nuntium
    sudo sh -c 'echo "<VirtualHost *:80>
  DocumentRoot /u/apps/nuntium/public
  SetEnv RAILS_ENV production
  RailsEnv production
  PassengerSpawnMethod conservative
  PassengerLogFile /var/log/nuntium/web.log
  <Directory /u/apps/nuntium/public>
    Allow from all
    Options -MultiViews
    Require all granted
  </Directory>
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf'

    sudo /etc/init.d/apache2 restart

    # Configure rabbitmq
    sudo rabbitmqctl add_user nuntium nuntium
    sudo rabbitmqctl set_user_tags nuntium administrator
    sudo rabbitmqctl add_vhost /nuntium
    sudo rabbitmqctl set_permissions -p /nuntium nuntium ".*" ".*" ".*"

    # Create logs folder
    sudo mkdir -p /var/log/nuntium
    sudo chown `whoami` /var/log/nuntium

    # Setup rails application
    sudo mkdir -p /u/apps/nuntium
    sudo chown `whoami` /u/apps/nuntium
    git clone /vagrant /u/apps/nuntium
    cd /u/apps/nuntium
    if [ "$1" != '' ]; then
      git checkout $1;
      echo $1 > VERSION;
    fi

    # Configuration files
    echo "production:
  adapter: mysql2
  host: mysql.local
  database: nuntium
  username: root
  password:
  pool: 5
  timeout: 5000
  reconnect: true
  encoding: utf8" > /u/apps/nuntium/config/database.yml

    echo "production:
  vhost: /nuntium
  user: nuntium
  pass: nuntium" > /u/apps/nuntium/config/amqp.yml

    echo "protocol: http
host_name: nuntium.example.com
email_sender: nuntium@example.com" > /u/apps/nuntium/config/settings.yml

    rm /u/apps/nuntium/config/google_oauth2.yml
    rm /u/apps/nuntium/config/newrelic.yml
    rm /u/apps/nuntium/config/twitter_oauth_consumer.yml

    # Bundle install
    bundle install --deployment --path .bundle --without "development test"

    # Setup assets
    bundle exec rake assets:precompile

    # Install services
    echo "HOME=$HOME
PATH=$PATH
RAILS_ENV=production" > /u/apps/nuntium/.env

    sudo `which bundle` exec foreman export upstart /etc/init -f /u/apps/nuntium/Procfile -a nuntium -u vagrant -l /var/log/nuntium/ --concurrency="web=0,worker_fast=1,worker_slow=1,xmpp=0,smpp=1,msn=0,cron=1,sched=1"
    sudo start nuntium

  SH
  end
end
