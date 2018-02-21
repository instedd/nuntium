FactoryBot.define do
  factory :message, aliases: [:ao_message, :at_message] do
    from { "sms://#{RandomGenerator.number8}" }
    to { "sms://#{RandomGenerator.number8}" }
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    timestamp { Time.at(946702800 + 86400 * rand(100)).getgm }
    guid RandomGenerator.guid
    state { 'queued' }
    email {
      {
        from: "mailto://#{Faker::Internet.email}",
        to: "mailto://#{Faker::Internet.email}"
      }
    }
  end
end
