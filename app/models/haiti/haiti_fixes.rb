module HaitiFixes

  HAITI_APP_IDS = [1,2,3]

  def haiti_fixed_number(target)
    return nil if target.nil?
    return target if not target.protocol.downcase == 'sms'
    number = target.without_protocol
    number = number[1..-1] if number[0..0] == '+'
    number = '509' + number if number.size == 8
    number.with_protocol 'sms'
  end

end