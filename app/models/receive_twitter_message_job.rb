require 'twitter'
require 'guid'

class ReceiveTwitterMessageJob
  attr_accessor :application_id, :channel_id

  def initialize(application_id, channel_id)
    @application_id = application_id
    @channel_id = channel_id
  end
  
  def perform
    @channel = Channel.find @channel_id
    @config = @channel.configuration
    @status = TwitterChannelStatus.first(:conditions => { :channel_id => @channel_id })
    @client = TwitterChannelHandler.new_client(@config)
    
    download_new_messages
    follow_and_send_welcome_to_new_followers
    
    if !@status.nil?
      @status.save
    end
  end
  
  def download_new_messages
    query = {:page => 1}
    
    # Use last_id if available
    if !@status.nil?
      query[:since_id] = @status.last_id
    end
    
    begin
      msgs = @client.direct_messages(query)
      
      # Remember last_id
      if query[:page] == 1 && !msgs.empty?
        if @status.nil?
          @status = TwitterChannelStatus.new(:channel_id => @channel_id)
        end
        @status[:last_id] = msgs[0].id
      end
      
      msgs.each do |twit|
        msg = ATMessage.new
        msg.application_id = @application_id
        msg.from = 'twitter://' + twit.sender_screen_name
        msg.to = 'twitter://' + twit.recipient_screen_name
        msg.subject = twit.text
        msg.timestamp = Time.parse(twit.created_at)
        msg.guid = twit.id
        msg.state = 'queued'
        msg.save
      end
      
      query[:page] += 1
    end until msgs.empty?
  end
  
  def follow_and_send_welcome_to_new_followers
    all_followers = []
    all_friends = []
    
    # Get followers
    query = {:page => 1}
    begin
      followers = @client.followers(query)
      followers.each do |follower|
        all_followers.push(follower.screen_name)
      end
      
      query[:page] += 1
    end until followers.empty?
    
    # Get friends
    query[:page] = 1
    begin
      friends = @client.friends(query)
      friends.each do |friend|
        all_friends.push(friend.screen_name)
      end
      
      query[:page] += 1
    end until friends.empty?
    
    # The new followers are:
    new_followers = all_followers - all_friends
    
    # For each: follow them and send welcome message
    has_welcome_message = !@config[:welcome_message].blank?
    new_followers.each do |follower|
      @client.friendship_create(follower, true)
      
      if has_welcome_message
        @client.direct_message_create(follower, @config[:welcome_message])
      end
    end
  end
  
  # Enqueues jobs of this class for each channel
  # found in the application
  def self.enqueue_for_all_channels
    Channel.find_each(:conditions => "kind = 'twitter'") do |chan|
      job = ReceiveTwitterMessageJob.new(chan.application_id, chan.id)
      Delayed::Job.enqueue job
    end
  end
  
end
