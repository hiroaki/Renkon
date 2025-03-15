require 'rails_helper'

RSpec.describe Article, type: :model do
  describe '基本' do
    let!(:article) { FactoryBot.build(:article) }
    it '既定の Factory が valid であり、レコードが保存できる' do
      expect { article.save! }.not_to raise_error
    end
  end

  describe 'バリデーション' do
    let!(:subscription) { FactoryBot.create(:subscription) }

    subject { described_class.new(params).valid? }

    context do
      let!(:params) { { subscription: subscription, title: "aaa", url: "http://example.com/" } }
      it { is_expected.to be true }
    end

    context do
      let!(:params) { { subscription: nil, title: "aaa", url: "http://example.com/" } }
      it { is_expected.to be false }
    end

    context do
      let!(:params) { { subscription: subscription, title: nil, url: "http://example.com/" } }
      it { is_expected.to be false }
    end

    context do
      let!(:params) { { subscription: subscription, title: "aaa", url: "" } }
      it { is_expected.to be false }
    end
  end

  describe '#unread?' do
    let!(:article) { FactoryBot.build(:article, unread: unread) }

    subject { article.unread? }

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
