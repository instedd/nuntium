module HaitiFixes

  HAITI_APP_IDS = [1,2,3]

  APP_REDIRECT_AT_FROM_ID = 1
  APP_REDIRECT_AT_TO_ID = 2
  APP_REDIRECT_PHONE = 'sms://200'
  
  def redirect_app(msg)
    msg.application_id = APP_REDIRECT_AT_TO_ID 
  end

  def route_app(msg, via)
    msg.application_id = APP_REDIRECT_AT_FROM_ID
    app = Application.find APP_REDIRECT_AT_FROM_ID
    return false if app.nil?
    app.route msg, via
  end

  def haiti_fixed_number(target)
    return nil if target.nil?
    return target if not target.protocol.downcase == 'sms'
    number = target.without_protocol
    number = number[1..-1] if number[0..0] == '+'
    number = '509' + number if number.size == 8
    number.with_protocol 'sms'
  end

end