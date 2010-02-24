#!/usr/bin/ruby
require 'rubygems'
require 'daemons'

Daemons.run('delayed_job_daemon.rb')
