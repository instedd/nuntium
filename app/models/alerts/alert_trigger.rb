class AlertTrigger

  def initialize(application)
    @application = application
    @alert_configurations = @application.alert_configurations
  end

  def alert(kind, msg)
    now = Time.now.utc
    alerts_for_kind = Alert.all(:conditions => ['application_id = ? and kind = ?', @application.id, kind], :include => :ao_message)
    pending_alerts = alerts_for_kind.select {|a| a.sent_at.nil? || (now - a.sent_at) < 1.hour.to_i}
    return unless pending_alerts.empty?
    
    @alert_configurations.each do |cfg|
      tos = cfg.to.split(',').map{|x| x.strip}
      
      tos.each do |to|
        alert = alerts_for_kind.select{|a| a.channel_id = cfg.channel_id && a.ao_message.to == to}.first
        ao_msg = AOMessage.create!(:application_id => @application.id, :from => cfg.from, :to => to, :subject => "Nuntium alert for #{@application.name}", :body => msg, :state => 'pending', :timestamp => Time.now.utc)
        @application.logger.ao_message_created_as_alert ao_msg
        if alert.nil?
          Alert.create!(:application_id => @application.id, :channel_id => cfg.channel_id, :kind => kind, :ao_message_id => ao_msg.id)
        else
          alert.ao_message_id = ao_msg.id
          alert.sent_at = nil
          alert.save!
        end
      end
    end
  end

end
