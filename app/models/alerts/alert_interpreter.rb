class AlertInterpreter

  def interpret_for(account)
    return if account.configuration[:alert].nil?
  
    trigger = AlertTrigger.new account
    begin
      eval account.configuration[:alert]
    rescue Exception => e
      trigger.alert "system_internal_#{Time.now.to_i}", fix_error("You have an error in your alert code: #{e.message}")
    end
  end
  
  def fix_error(msg)
    msg.gsub('.', ' ')
  end

end
