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

class TwitterController < ChannelsController
  include CustomAttributesControllerCommon
  include RulesControllerCommon

  before_filter :set_channel_parameters, :only => [:create, :update]
  before_filter :check_twitter_properly_configured

  def create
    if channel.save
      go_to_twitter
    else
      render "channels/new"
    end
  end

  def update
    if channel.save
      go_to_twitter
    else
      render "channels/edit"
    end
  end

  def callback
    client = TwitterChannel.new_client
    access_token = client.authorize session['twitter_token'], session['twitter_secret'], oauth_verifier: params[:oauth_verifier]

    unless client.authorized?
      raise "Client couldn't be verified"
    end

    profile = client.info

    @channel = Channel.find session['twitter_channel_id']
    @update = !@channel.new_record?

    @channel.screen_name = profile['screen_name']
    @channel.token = access_token.token
    @channel.secret = access_token.secret

    session['twitter_token']  = nil
    session['twitter_secret'] = nil
    session['twitter_channel_id'] = nil

    if @channel.save
      flash[:notice] = @update ? "Channel #{@channel.name} was updated" : "Channel #{@channel.name} was created"
    else
      flash[:notice] = "Channel #{@channel.name} couldn't be saved"
    end
    redirect_to channels_path
  end

  protected

  def go_to_twitter
    request_token = TwitterChannel.request_token

    session['twitter_token'] = request_token.token
    session['twitter_secret'] = request_token.secret
    session['twitter_channel_id'] = channel.id

    redirect_to request_token.authorize_url
  end

  def check_twitter_properly_configured
    return redirect_to_home if Nuntium::TwitterConsumerConfig.nil?
  end
end
