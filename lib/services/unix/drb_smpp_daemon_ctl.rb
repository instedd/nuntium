#!/usr/bin/ruby
require 'rubygems'
require 'daemons'

Daemons.run('drb_smpp_daemon.rb')
