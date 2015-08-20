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

def start_service(log_name)
  $log_path = File.expand_path("../../../log/#{log_name}.log", __FILE__)

  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

  require File.expand_path('../../../config/boot',  __FILE__)
  require File.expand_path('../../../config/environment',  __FILE__)

  EM.run {
    yield
  }
rescue SystemExit
  Rails.logger.info "Stopping service normally"
rescue Exception => err
  Rails.logger.error("Daemon failure: #{err} #{err.backtrace}") rescue STDERR.puts("Daemon failure: #{err} #{err.backtrace}")
end
