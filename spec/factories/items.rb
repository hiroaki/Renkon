FactoryBot.define do
  factory :item do
    association :channel
    sequence :title do |n|
      "Title ##{n}"
    end
    sequence :url do |n|
      "http://example.com/#{n}"
    end
  end
end
