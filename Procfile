web: bundle exec rails s
worker_fast: bundle exec lib/services/generic_worker_daemon.rb ${RAILS_ENV:-development} fast $PORT
worker_slow: bundle exec lib/services/generic_worker_daemon.rb ${RAILS_ENV:-development} slow $PORT
xmpp: bundle exec lib/services/xmpp_service_daemon.rb
smpp: bundle exec lib/services/smpp_service_daemon.rb
smpp_server: bundle exec lib/services/smpp_server_service_daemon.rb
msn: bundle exec lib/services/msn_service_daemon.rb
cron: bundle exec lib/services/cron_daemon.rb
sched: bundle exec lib/services/scheduled_jobs_service_daemon.rb
