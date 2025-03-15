FactoryBot.define do
  factory :subscription do
    title { "String" }
    src { "http://example.com/rss" }

    trait :with_articles do
      transient do
        number_of_articles { 3 }
      end

      after(:create) do |subscription, evaluator|
        create_list(:article, evaluator.number_of_articles, subscription: subscription)
      end
    end
  end
end
