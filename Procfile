web: bundle exec rails s
worker_fast: lib/services/generic_worker_daemon.rb ${RAILS_ENV:-development} fast $PORT
worker_slow: lib/services/generic_worker_daemon.rb ${RAILS_ENV:-development} slow $PORT
xmpp: lib/services/xmpp_service_daemon.rb
smpp: lib/services/smpp_service_daemon.rb
msn: lib/services/msn_service_daemon.rb
cron: lib/services/cron_daemon.rb
sched: lib/services/scheduled_jobs_service_daemon.rb