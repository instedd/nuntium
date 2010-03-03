#!/usr/bin/ruby
require(File.join(File.dirname(__FILE__), 'generic_ctl'))
run('drb_smpp_daemon', ARGV[3])
