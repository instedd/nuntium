#!/usr/bin/ruby
require 'rubygems'
require 'daemons'

Daemons.run('cron_daemon.rb')
