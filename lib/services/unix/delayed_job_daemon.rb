#!/usr/bin/ruby
require(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'boot'))
require(File.join(RAILS_ROOT, 'config', 'environment'))

Delayed::Command.new(ARGV).daemonize
