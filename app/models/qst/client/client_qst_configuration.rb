class ClientQstConfiguration

  def initialize(parent)
    @parent = parent
  end

  def user
    configuration[:user]
  end

  def pass
    configuration[:password]
  end

  def url
    configuration[:url]
  end
  
  def max_tries
    configuration[:max_tries] || 5
  end
  
  def last_at_guid
    configuration[:last_at_guid]
  end
  
  def last_ao_guid
    configuration[:last_ao_guid]
  end

  def set_last_at_guid(value)
    configuration[:last_at_guid] = value
    @parent.save
  end
  
  def set_last_ao_guid(value)
    configuration[:last_ao_guid] = value
    @parent.save
  end
  
  def logger
    @parent.account.logger
  end
  
  private
  
  def configuration
    @parent.configuration ||= {}
  end

end
