#!/bin/sh
# source: http://mpas.github.io/blog/2015/06/11/setting-up-docker-rabbitmq-with-predefined-users/vhosts/

# Create Default RabbitMQ setup
( sleep 5 ; \

rabbitmqctl add_user nuntium.development nuntium.development ; \
rabbitmqctl set_user_tags nuntium.development administrator ; \

rabbitmqctl add_user nuntium.test nuntium.test ; \
rabbitmqctl set_user_tags nuntium.test administrator ; \

rabbitmqctl add_user nuntium nuntium ; \
rabbitmqctl set_user_tags nuntium administrator ; \

rabbitmqctl add_vhost /nuntium/development ; \
rabbitmqctl add_vhost /nuntium/test ; \
rabbitmqctl add_vhost /nuntium ; \

rabbitmqctl set_permissions -p /nuntium/development nuntium.development ".*" ".*" ".*" ; \
rabbitmqctl set_permissions -p /nuntium/test nuntium.test ".*" ".*" ".*" ; \
rabbitmqctl set_permissions -p /nuntium nuntium ".*" ".*" ".*" ; \

) &
rabbitmq-server $@
