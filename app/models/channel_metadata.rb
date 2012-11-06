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

module ChannelMetadata
  extend ActiveSupport::Concern

  included do
    self.inheritance_column = :kind
  end

  module InstanceMethods
    def job_class
      "Send#{self.class.identifier}MessageJob".constantize
    end

    def create_job(msg)
      job_class.new(account_id, id, msg.id)
    end
  end

  module ClassMethods
    def kinds
      @@kinds ||= begin
                    # Load all channels
                    Dir.glob("#{Rails.root}/app/models/**/*_channel.rb").each do |file|
                      eval(ActiveSupport::Inflector.camelize(file[file.rindex('/') + 1 .. -4]))
                    end

                    Object.subclasses_of(Channel).map do |clazz|
                      # Put the title and kind in array
                      [clazz.title, clazz.kind]
                    end.sort do |a1, a2|
                      # And sort by title
                      a1[0] <=> a2[0]
                    end
                  end
      @@kinds.map{|x| [x[0].dup, x[1].dup]}
    end

    def identifier
      /(.*?)Channel/.match(self.name)[1]
    end

    def title
      identifier.titleize
    end

    def kind
      identifier.underscore
    end

    # We want the SmtpChannel class given the "smtp" kind
    def find_sti_class(type_name)
      type_name.try(:to_channel) || Channel
    end

    # We want the single table inheritance name (the kind column) to be "smtp", not "SmtpChannel"
    def sti_name
      super.tableize[0 .. -10]
    end
  end
end
