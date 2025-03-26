FactoryBot.define do
  factory :subscription do
    title { "String" }
    src { "http://example.com/rss" }

    trait :with_articles do
      transient do
        number_of_articles { 3 }
        unread { true } # 'unread' を transients で定義
      end

      after(:create) do |subscription, evaluator|
        create_list(:article, evaluator.number_of_articles, subscription: subscription, unread: evaluator.unread)
      end
    end

    trait :with_favicon do
      favicon { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'favicon.ico'), 'image/x-icon') }
    end
  end
end
