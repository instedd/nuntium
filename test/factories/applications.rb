FactoryBot.define do
  factory :application, aliases: [:application_rss], class: Application do
    name Faker::Internet.user_name
    account
    interface { "rss" }
    password Faker::Internet.password
    password_confirmation { password }

    factory :application_broadcast do
      configuration { { strategy: 'broadcast' } }
    end

    factory :application_http_get_callback do
      interface { "http_get_callback" }
      configuration { { interface_url: Faker::Internet.domain_name, interface_user: Faker::Internet.user_name, interface_password: Faker::Internet.password } }
    end

    factory :application_http_post_callback do
      interface { "http_post_callback" }
      configuration { { interface_url: Faker::Internet.domain_name, interface_user: Faker::Internet.user_name, interface_password: Faker::Internet.password } }
    end

    factory :application_qst_client do
      interface { "qst_client" }
      configuration { { interface_url: Faker::Internet.domain_name, interface_user: Faker::Internet.user_name, interface_password: Faker::Internet.password } }
    end
  end
end
