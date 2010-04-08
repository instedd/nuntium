require 'twitter'
require 'guid'

class ReceiveTwitterMessageJob
  attr_accessor :application_id, :channel_id
  
  include CronTask::QuotedTask

  def initialize(application_id, channel_id)
    @application_id = application_id
    @channel_id = channel_id
  end
  
  def perform
    @application = Application.find @application_id
    @channel = Channel.find @channel_id
    @config = @channel.configuration
    @status = TwitterChannelStatus.first(:conditions => { :channel_id => @channel_id })
    
    begin
      @client = TwitterChannelHandler.new_client(@config)
      download_new_messages
      follow_and_send_welcome_to_new_followers
    rescue => e
      ApplicationLogger.exception_in_channel @channel, e
      raise
    ensure
      @status.save unless @status.nil?
    end
  end
  
  def download_new_messages
    query = {:page => 1, :count => 200}
    
    # Use last_id if available
    query[:since_id] = @status.last_id unless @status.nil?
    
    begin
      msgs = @client.direct_messages(query)
      @status ||= TwitterChannelStatus.new(:channel_id => @channel_id)
      
      # Remember last_id
      if query[:page] == 1 && !msgs.empty?
        @status[:last_id] = msgs[0].id
      end
      
      msgs.each do |twit|
        msg = ATMessage.new
        msg.from = "twitter://#{twit.sender_screen_name}"
        msg.to ="twitter://#{twit.recipient_screen_name}"
        msg.subject = twit.text
        msg.timestamp = Time.parse(twit.created_at)
        msg.channel_relative_id = twit.id
        
        @application.accept msg, @channel
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
      follower_ids_result['ids'].each do |follower_id|
        all_followers.push(follower_id)
      end
      
      query[:cursor] = follower_ids_result['next_cursor']
    end until query[:cursor] == 0 or not has_quota?
    return if not has_quota?
    
    # Get friends
    query = {:cursor => -1}
    begin
      friend_ids_result = @client.friend_ids(query)
      friend_ids_result['ids'].each do |friend_id|
        all_friends.push(friend_id)
      end
      
      query[:cursor] = friend_ids_result['next_cursor']
    end until query[:cursor] == 0 or not has_quota?
    return if not has_quota?
    
    # The new followers are:
    new_followers = all_followers - all_friends
    
    # For each: follow them and send welcome message
    has_welcome_message = !@config[:welcome_message].blank?
    new_followers.each do |follower|
      @client.friendship_create(follower, true)
      @client.direct_message_create(follower, @config[:welcome_message]) if has_welcome_message
      return if not has_quota?
    end
  end
  
end
