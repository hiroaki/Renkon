FactoryBot.define do
  factory :article do
    association :subscription
    sequence :title do |n|
      "Title ##{n}"
    end
    sequence :url do |n|
      "http://example.com/#{n}"
    end
  end
end
