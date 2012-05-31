# Copyright (C) 2009-2012, InSTEDD
# 
# This file is part of Nuntium.
# 
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

#!/usr/bin/env ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
if ARGV.length != 2
  puts "Usage: ./service_daemon.rb <environment> <channel_id>"
else
  start_service "service_daemon_#{ARGV[1]}" do
    begin
      channel_id = ARGV[1]
      channel = Channel.find_by_id channel_id
      if channel
        channel.service.start
        EM.reactor_thread.join
      else
        Rails.logger.error "No channel found for id #{channel_id}"
      end
    rescue SystemExit
      Rails.logger.info "Stopping service normally"
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
      exit -1
    end
  end
end
