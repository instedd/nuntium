class CustomAttribute < ActiveRecord::Base
  serialize :custom_attributes, Hash
end
