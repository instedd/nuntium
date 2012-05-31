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

class SendTwitterMessageJob < SendMessageJob
  def managed_perform
    client = TwitterChannel.new_client(@config)
    response = client.direct_message_create(@msg.to.without_protocol, @msg.subject_and_body)
    @msg.channel_relative_id = response.id
  rescue Twitter::General => ex
    raise MessageException.new(ex)
  rescue Twitter::NotFound => ex
    raise MessageException.new(ex)
  rescue Twitter::Unauthorized => ex
    raise PermanentException.new(ex)
  end
end
