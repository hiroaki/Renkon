require 'rails_helper'

RSpec.describe FeedCache, type: :model do
  describe '基本' do
    let!(:feed_cache) { FactoryBot.build(:feed_cache) }
    it '既定の Factory が valid であり、レコードが保存できる' do
      expect { feed_cache.save! }.not_to raise_error
    end
  end
end

RSpec.describe FeedCache, type: :model do
  let(:subscription) { FactoryBot.create(:subscription) }
  let(:feed_cache) { FactoryBot.create(:feed_cache, subscription: subscription) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(feed_cache).to be_valid
    end

    it 'is not valid without a subscription_id' do
      feed_cache.subscription_id = nil
      expect(feed_cache).not_to be_valid
    end

    it 'is valid without contents' do
      feed_cache.contents = nil
      expect(feed_cache).to be_valid
    end

    it 'is valid without cached_at' do
      feed_cache.cached_at = nil
      expect(feed_cache).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a subscription' do
      expect(feed_cache).to respond_to(:subscription)
    end
  end
end