
module MessageGetter
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    # Given either a string guid, numeric id or a message returns the corresponding message
    def get_message(msg_or_id)
      if msg_or_id.kind_of? ActiveRecord::Base
        return msg_or_id
      elsif msg_or_id.kind_of? Numeric
        return self.find_by_id(msg_or_id)
      elsif msg_or_id.kind_of? String
        return self.find_by_guid(msg_or_id)
      else
        return msg_or_id
      end
    end
  end
  
end

