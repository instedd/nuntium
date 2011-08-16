module MessageGetter
  extend ActiveSupport::Concern

  module ClassMethods
    def get_message(msg_or_id)
      if msg_or_id.kind_of? ActiveRecord::Base
        msg_or_id
      elsif msg_or_id.kind_of? Numeric
        find_by_id(msg_or_id)
      elsif msg_or_id.kind_of? String
        find_by_guid(msg_or_id)
      else
        msg_or_id
      end
    end
  end
end
