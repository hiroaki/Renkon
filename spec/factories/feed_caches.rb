FactoryBot.define do
  factory :feed_cache do
    association :subscription
    contents { nil }
    cached_at { "2025-02-24 18:38:58" }
  end
end
