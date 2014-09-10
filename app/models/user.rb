class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :password, :password_confirmation, :remember_me

  belongs_to :current_account, :class_name => 'Account'
  has_many :user_accounts
  has_many :user_applications
  has_many :user_channels
  has_many :accounts, :through => :user_accounts
  has_many :applications, :through => :user_applications
  has_many :channels, :through => :user_channels
  has_many :identities, dependent: :destroy

  def display_name
    name || email
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

  def join_account(account, role = :member)
    make_default_account_if_first(account) do
      existing = UserAccount.find_by_user_id_and_account_id id, account.id
      unless existing
        UserAccount.create! user_id: id, account_id: account.id, role: role
      end
    end
  end

  def self.authenticate(email, token, options = {})
    user = User.find_by_email email
    if user && user.authentication_token == token
      return user
    end
    nil
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
