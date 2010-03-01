#!/usr/bin/ruby
require 'rubygems'
require 'daemons'

Daemons.run(File.join(File.dirname(__FILE__), 'throttled_job_daemon.rb'))
