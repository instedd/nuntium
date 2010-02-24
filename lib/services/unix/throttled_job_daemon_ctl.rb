#!/usr/bin/ruby
require 'rubygems'
require 'daemons'

Daemons.run('throttled_job_daemon.rb')
