FactoryBot.define do
  factory :channel do
    title { "String" }
    src { "http://example.com/rss" }

    trait :with_items do
      transient do
        number_of_items { 3 }
      end

      after(:create) do |channel, evaluator|
        create_list(:item, evaluator.number_of_items, channel: channel)
      end
    end
  end
end
