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

class ReceiveTwitterMessageJob
  attr_accessor :account_id, :channel_id

  include CronTask::QuotedTask

  def initialize(account_id, channel_id)
    @account_id = account_id
    @channel_id = channel_id
  end

  def perform
    @account = Account.find @account_id
    @channel = @account.channels.find_by_id @channel_id
    @config = @channel.configuration
    @status = @channel.twitter_channel_statuses.first

    begin
      @client = @channel.new_authorized_client
      download_new_messages
      follow_and_send_welcome_to_new_followers
    rescue Twitter::Error::Unauthorized => ex
      @channel.alert "#{ex}"

      @channel.enabled = false
      @channel.save!
      return
    ensure
      @status.save unless @status.nil?
    end
  rescue => ex
    AccountLogger.exception_in_channel @channel, ex if @channel
  end

  def download_new_messages
    query = {:page => 1, :count => 200}

    # Use last_id if available
    query[:since_id] = @status.last_id.to_i unless @status.nil?

    begin
      msgs = @client.direct_messages(query)
      @status ||= @channel.twitter_channel_statuses.new

      # Remember last_id
      if query[:page] == 1 && !msgs.empty?
        @status[:last_id] = msgs[0].id.to_i
      end

      msgs.each do |twit|
        if twit.created_at < @channel.created_at
          Rails.logger.info "Skipping message from #{twit.sender.screen_name} (#{twit.text}) because it's old (#{twit.created_at})"
          next
        end

        msg = AtMessage.new
        msg.from = "twitter://#{twit.sender.screen_name}"
        msg.to ="twitter://#{twit.recipient.screen_name}"
        msg.body = twit.text
        msg.timestamp = twit.created_at
        msg.channel_relative_id = twit.id

        @account.route_at msg, @channel
      end

      query[:page] += 1
    end until msgs.empty? or not has_quota?
  end

  def follow_and_send_welcome_to_new_followers
    all_followers = []
    all_friends = []
    return if not has_quota?

    # Get followers
    query = {:cursor => -1}
    begin
      follower_ids_result = @client.follower_ids(query)
      follower_ids_result.each do |follower_id|
        all_followers.push(follower_id)
      end

      query[:cursor] = follower_ids_result.next_cursor
    end until query[:cursor] <= 0 || !has_quota?
    return unless has_quota?

    # Get friends
    query = {:cursor => -1}
    begin
      friend_ids_result = @client.friend_ids(query)
      friend_ids_result.each do |friend_id|
        all_friends.push(friend_id)
      end

      query[:cursor] = friend_ids_result.next_cursor
    end until query[:cursor] <= 0 || !has_quota?
    return unless has_quota?

    # The new followers are:
    new_followers = all_followers - all_friends

    @client.follow!(*new_followers, follow: true)

    # For each: follow them and send welcome message
    has_welcome_message = !@config[:welcome_message].blank?
    if has_welcome_message
      new_followers.each do |follower|
        @client.direct_message_create(follower, @config[:welcome_message])
        return unless has_quota?
      end
    end
  end
end
