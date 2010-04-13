#!/usr/bin/ruby
require(File.join(File.dirname(__FILE__), 'generic_ctl'))
run('cron_worker_daemon', ARGV[3])
