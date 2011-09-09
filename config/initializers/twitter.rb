if defined? Twitter
  # This is a monkey patch for the friendships/exists call.
  # Twitter returns true or false and JSON.parse chokes on it.
  # So we handle those values separately.
  module Twitter
    def self.parse(response)
      return '' if response.body == ''
      return true if response.body == 'true'
      return false if response.body == 'false'
      JSON.parse(response.body)
    end
  end
end
