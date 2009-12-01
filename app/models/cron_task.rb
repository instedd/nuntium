class CronTask < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true
  
  validates_numericality_of :interval, :greater_than_or_equal_to => 0
  
  def execute
    if not self.code.nil?
      eval(self.code)
    end
  end
  
end
