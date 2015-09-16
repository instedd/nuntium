class UserChannel < ActiveRecord::Base
  belongs_to :account
  belongs_to :user
  belongs_to :channel

  validates_presence_of :user
  validates_presence_of :channel

  after_save :update_account_lifespan

  private

  def update_account_lifespan
    touch_account_lifespan(self.account)
  end
end
