require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'associations' do
    it { should belong_to(:parent).class_name('Group').optional }
    it { should have_many(:children).class_name('Group').with_foreign_key('parent_id').dependent(:destroy) }
    it { should have_many(:subscriptions).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'position ordering' do
    it 'assigns next position among mixed siblings within parent group' do
      parent = FactoryBot.create(:group, position: 1)
      FactoryBot.create(:group, parent: parent, position: 1)
      FactoryBot.create(:subscription, group: parent, position: 4)

      child = described_class.create!(name: 'Child', parent: parent)
      expect(child.position).to eq(5)
    end

    it 'assigns next position among mixed siblings at top-level' do
      FactoryBot.create(:group, parent: nil, position: 2)
      FactoryBot.create(:subscription, group: nil, position: 6)

      top_group = described_class.create!(name: 'Top Group', parent: nil)
      expect(top_group.position).to eq(7)
    end

    it 'orders by position and id' do
      first = FactoryBot.create(:group, position: 2)
      second = FactoryBot.create(:group, position: 1)
      third = FactoryBot.create(:group, position: 2)

      expect(described_class.ordered.pluck(:id)).to eq([second.id, first.id, third.id])
    end
  end

  describe '.default_root!' do
    it 'creates a root group when none exists' do
      expect { described_class.default_root! }.to change(described_class, :count).by(1)
      expect(described_class.default_root!.name).to eq('Subscriptions')
    end

    it 'reuses existing root group' do
      root = FactoryBot.create(:group, name: 'Root', parent: nil, position: 1)

      expect(described_class.default_root!).to eq(root)
    end
  end
end
