class UserAccount < ActiveRecord::Base
  belongs_to :user
  belongs_to :account

  validates_presence_of :user
  validates_presence_of :account

  after_save :update_account_lifespan

  private

  def update_account_lifespan
    touch_account_lifespan(self.account)
  end
end
