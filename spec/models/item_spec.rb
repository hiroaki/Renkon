require 'rails_helper'

RSpec.describe Item, type: :model do
  describe '基本' do
    let!(:item) { FactoryBot.build(:item) }
    it '既定の Factory が valid であり、レコードが保存できる' do
      expect { item.save! }.not_to raise_error
    end
  end

  describe 'バリデーション' do
    let!(:channel) { FactoryBot.create(:channel) }

    subject { described_class.new(params).valid? }

    context do
      let!(:params) { { channel: channel, title: "aaa", url: "http://example.com/" } }
      it { is_expected.to be true }
    end

    context do
      let!(:params) { { channel: nil, title: "aaa", url: "http://example.com/" } }
      it { is_expected.to be false }
    end

    context do
      let!(:params) { { channel: channel, title: nil, url: "http://example.com/" } }
      it { is_expected.to be false }
    end

    context do
      let!(:params) { { channel: channel, title: "aaa", url: "" } }
      it { is_expected.to be false }
    end
  end

  describe '#unread?' do
    let!(:item) { FactoryBot.build(:item, unread: unread) }

    subject { item.unread? }

    context do
      let!(:unread) { true }
      it { is_expected.to be true }
    end

    context do
      let!(:unread) { false }
      it { is_expected.to be false }
    end
  end
end
