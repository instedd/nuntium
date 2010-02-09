class AlertInterpreter

  def interpret_for(application)
    return if application.configuration[:alert].nil?
  
    trigger = AlertTrigger.new application
    begin
      eval application.configuration[:alert]
    rescue Exception => e
      trigger.alert 'system_internal', fix_error("You have an error in your alert code: #{e.message}")
    end
  end
  
  def fix_error(msg)
    msg.gsub('.', ' ')
  end

end
