FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    sequence(:position) { |n| n }
    parent { nil }
  end
end
