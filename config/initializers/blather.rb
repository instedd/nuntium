class Blather::Stanza::Message
  def error_code
    xpath('error').attr('code').value
  end

  def error_type
    xpath('error').attr('type').value
  end
end
