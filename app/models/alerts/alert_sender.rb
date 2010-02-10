class AlertSender

  def initialize
    @logger = Logger.new(File.join(File.dirname(__FILE__), '..', '..', '..', 'log', 'alerts.log'))
    @logger.formatter = Logger::Formatter.new
  end

  def perform
    Alert.all(:conditions => 'sent_at is null').each do |alert|
      begin
        next if alert.channel.nil?
      
        ao_msg = AOMessage.find_by_id alert.ao_message_id
        next if ao_msg.nil?
        
        if ao_msg.tries >= 3
          ao_msg.state = 'failed'
          ao_msg.save!
          alert.failed = true
          alert.sent_at = Time.now.utc
          alert.save!
          return
        end
        
        alert.channel.handle_now(ao_msg)
        alert.sent_at = Time.now.utc
        alert.save!
      rescue Exception => e
        @logger.error "#{e.class} #{e.message}"
      end
    end
  end

end
