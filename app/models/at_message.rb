class ATMessage < ActiveRecord::Base
  belongs_to :application
  validates_presence_of :application
end
