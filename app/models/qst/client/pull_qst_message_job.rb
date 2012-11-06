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

class PullQstMessageJob < AbstractPullQstMessageJob
  include ApplicationQstConfiguration

  def initialize(application_id)
    @application_id = application_id
    @batch_size = 10
  end

  def message_class
    AoMessage
  end

  def load_last_id
    application.last_ao_guid
  end

  def save_last_id(last_id)
    application.last_ao_guid = last_id
    application.save!
  end

  def route(msg)
    application.route_ao msg, 'qst_client'
  end
end
