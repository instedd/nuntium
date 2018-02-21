FactoryBot.define do
  factory :user, class: User do
    email Faker::Internet.email
    password Faker::Internet.password
    password_confirmation { password }
    confirmed_at (DateTime.now - 1.hour)
  end

  factory :user_application, class: UserApplication do
    user
    application
    account { application.account }
  end

  factory :user_account, class: UserAccount do
    user
    account
  end

  factory :user_channel, class: UserChannel do
    user
    channel qst_client_channel
  end
end
