class UserApplication < ActiveRecord::Base
  belongs_to :account
  belongs_to :user
  belongs_to :application

  validates_presence_of :user
  validates_presence_of :application

  after_save :update_application_lifespan
  after_save :update_account_lifespan

  private

  def update_application_lifespan
    touch_application_lifespan(self.application)
  end

  def update_account_lifespan
    touch_account_lifespan(self.account)
  end
end
