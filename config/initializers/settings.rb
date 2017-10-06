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

require 'socket'

class Settings
  ConfigFilePath = "#{::Rails.root.to_s}/config/settings.yml"

  if FileTest.exists?(ConfigFilePath)
    @@config = YAML.load_file(ConfigFilePath)[::Rails.env]
  else
    @@config = {}
  end

  class << self
    def method_missing(method_sym, *arguments, &block)
      @@config[method_sym.to_s]
    end

    def setting name, default
      self.class.send :define_method, name do
        @@config[name.to_s] || default
      end
    end
  end

  # Settings with default value
  setting :protocol, ENV['SCHEME'] || 'https'
  setting :host_name, ENV['HOSTNAME'] || Socket.gethostname
  setting :email_sender, 'nuntium@instedd.org'
end
