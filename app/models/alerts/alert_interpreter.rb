class AlertInterpreter

  def interpret_for(app)
    return if app.configuration[:alert].nil?
  
    trigger = AlertTrigger.new app
    begin
      eval app.configuration[:alert]
    rescue Exception => e
      trigger.alert 'system_internal', fix_error("You have an error in your alert code: #{e.message}")
    end
  end
  
  def fix_error(msg)
    msg.gsub('.', ' ')
  end

end
