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

class Log < ActiveRecord::Base
  belongs_to :account
  belongs_to :application
  belongs_to :channel
  belongs_to :ao_message
  belongs_to :at_message

  Info = 1
  Warning = 2
  Error = 3

  ResultsPerPage = 10

  def severity_text
    case severity
    when Info then 'info'
    when Warning then 'warning'
    when Error then 'error'
    end
  end

  def severity_html
    case severity
    when Info then '<span style="color:#0D0D68">info</span>'
    when Warning then '<span style="color:#FF8B17">warning</span>'
    when Error then '<span style="color:red">error</span>'
    end
  end

  def self.severity_from_text(text)
    text = text.downcase
    return Info if 'info'.starts_with? text
    return Warning if 'warning'.starts_with? text
    return Error if 'error'.starts_with? text
    return 0
  end

  def self.search(search, options = {})
    result = self

    search = Search.new search
    if search.search
      severity = severity_from_text search.search
      if severity == 0
        result = result.where 'message LIKE ?', "%#{search.search}%"
      else
        result = result.where 'message LIKE ? OR severity = ?', "%#{search.search}%", severity
      end
    end
    if search[:severity]
      op, val = Search.get_op_and_val search[:severity]
      result = result.where "severity #{op} ?", severity_from_text(val)
    end
    [:ao, :ao_message_id, :ao_message].each do |sym|
      if search[sym]
        op, val = Search.get_op_and_val search[sym]
        result = result.where "ao_message_id #{op} ?", val.to_i
      end
    end
    [:at, :at_message_id, :at_message].each do |sym|
      if search[sym]
        op, val = Search.get_op_and_val search[sym]
        result = result.where "at_message_id #{op} ?", val.to_i
      end
    end
    if search[:after]
      after = Time.smart_parse search[:after]
      result = result.where 'created_at >= ?', after if after
    end
    if search[:before]
      before = Time.smart_parse search[:before]
      result = result.where 'created_at <= ?', before if before
    end
    if search[:channel]
      if options[:account]
        channel = options[:account].channels.select(:id).find_by_name search[:channel]
        if channel
          result = result.where :channel_id => channel.id
        else
          result = result.where '1 = 2'
        end
      else
        result = result.joins(:channel).where 'channels.name = ?', search[:channel]
      end
    end
    if search[:application]
      if options[:account]
        app = options[:account].applications.select(:id).find_by_name search[:application]
        if app
          result = result.where :application_id => app.id
        else
          result = result.where '1 = 2'
        end
      else
        result = result.joins(:application).where 'applications.name = ?', search[:application]
      end
    end
    result
  end

  def self.paginate_logs(options = {})
    result = self

    # Set total_entries to prevent execution of a SELECT COUNT(*) query but
    # still enable Next links
    page = (options[:page] || 1).to_i
    per_page = options[:per_page] || ResultsPerPage
    result = result.paginate :page => page, :per_page => per_page, :total_entries => page * per_page + 1
    result = result.all
    result.total_entries -= 1 if result.size == 0

    result
  end
end
