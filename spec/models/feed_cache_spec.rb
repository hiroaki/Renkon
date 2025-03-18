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
  pending "add some examples to (or delete) #{__FILE__}"
end
