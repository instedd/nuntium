class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  belongs_to :current_account, :class_name => 'Account'
  has_many :user_accounts
  has_many :user_applications
  has_many :user_channels
  has_many :accounts, :through => :user_accounts
  has_many :applications, :through => :user_applications
  has_many :channels, :through => :user_channels

  def display_name
    email
  end

  def has_accounts?
    user_accounts.exists?
  end

  def create_account(account)
    return false unless account.save

    make_default_account_if_first(account) do
      UserAccount.create! user_id: id, account_id: account.id, role: :admin
    end

    account
  end

  def join_account(account)
    make_default_account_if_first(account) do
      UserAccount.create! user_id: id, account_id: account.id, role: :member
    end
  end

  private

  def make_default_account_if_first(account)
    had_accounts = has_accounts?

    result = yield

    unless had_accounts
      self.current_account_id = account.id
      self.save!
    end

    result
  end
end
