require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'associations' do
    it { should belong_to(:parent).class_name('Group').optional }
    it { should have_many(:children).class_name('Group').with_foreign_key('parent_id').dependent(:nullify) }
    it { should have_many(:subscriptions).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'position ordering' do
    it 'assigns next position among siblings' do
      parent = FactoryBot.create(:group, position: 1)
      FactoryBot.create(:group, parent: parent, position: 1)

      child = described_class.create!(name: 'Child', parent: parent)
      expect(child.position).to eq(2)
    end

    it 'orders by position and id' do
      first = FactoryBot.create(:group, position: 2)
      second = FactoryBot.create(:group, position: 1)
      third = FactoryBot.create(:group, position: 2)

      expect(described_class.ordered.pluck(:id)).to eq([second.id, first.id, third.id])
    end
  end
end
