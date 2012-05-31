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

class RepublishAtJob
  attr_accessor :application_id
  attr_accessor :message_id
  attr_accessor :job

  def initialize(application_id, message_id, job)
    @application_id = application_id
    @message_id = message_id
    @job = job
  end

  def perform
    msg = AtMessage.find @message_id
    return if msg.state != 'delayed'

    msg.state = 'queued'
    msg.save!

    app = Application.find @application_id
    Queues.publish_application(app, @job)
  end
end
