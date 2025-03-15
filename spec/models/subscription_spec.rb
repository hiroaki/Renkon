require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe '基本' do
    let!(:subscription) { FactoryBot.build(:subscription) }
    it '既定の Factory が valid であり、レコードが保存できる' do
      expect { subscription.save! }.not_to raise_error
    end
  end

  describe 'バリデーション' do
    subject { described_class.new(params).valid? }

    context do
      let!(:params) { { title: "aaa", src: "http://example.com/rss" } }
      it { is_expected.to be true }
    end

    context do
      let!(:params) { { title: nil, src: "http://example.com/rss" } }
      it { is_expected.to be false }
    end

    context do
      let!(:params) { { title: "aaa", src: "" } }
      it { is_expected.to be false }
    end
  end

  describe '.all_with_count_articles' do
    let!(:subscription1) { FactoryBot.create(:subscription) }
    let!(:subscription2) { FactoryBot.create(:subscription) }
    let!(:subscription3) { FactoryBot.create(:subscription) }

    before do
      FactoryBot.create(:article, title: 'ch1-1', subscription: subscription1, unread: true, disabled: false)
      FactoryBot.create(:article, title: 'ch1-2', subscription: subscription1, unread: true, disabled: true)
      FactoryBot.create(:article, title: 'ch1-3', subscription: subscription1, unread: false, disabled: false)
      FactoryBot.create(:article, title: 'ch1-4', subscription: subscription1, unread: false, disabled: true)

      FactoryBot.create(:article, title: 'ch3-1', subscription: subscription3, unread: true, disabled: false)
      FactoryBot.create(:article, title: 'ch3-2', subscription: subscription3, unread: true, disabled: true)
      FactoryBot.create(:article, title: 'ch3-3', subscription: subscription3, unread: true, disabled: false)
      FactoryBot.create(:article, title: 'ch3-4', subscription: subscription3, unread: true, disabled: true)
    end

    describe 'subscriptions count' do
      context do
        it {
          rel = described_class.all_with_count_articles
          expect(rel.to_a.size).to eq 3
        }
      end

      context do
        it {
          rel = described_class.all_with_count_articles(unread: true)
          expect(rel.to_a.size).to eq 3
        }
      end

      context do
        it {
          rel = described_class.all_with_count_articles(unread: false)
          expect(rel.to_a.size).to eq 3
        }
      end
    end

    describe 'count of articles of subscription#1' do
      context do
        let!(:unread) { true }
        let!(:rel) { described_class.all_with_count_articles(unread: unread) }
        it { expect(rel.find { |r| r.id == subscription1.id }.count_articles(unread: unread)).to eq 1 }
      end
      context do
        let!(:unread) { false }
        let!(:rel) { described_class.all_with_count_articles(unread: unread) }
        it { expect(rel.find { |r| r.id == subscription1.id }.count_articles(unread: unread)).to eq 2 }
      end
    end

    describe 'count of articles of subscription#2' do
      context do
        let!(:unread) { true }
        let!(:rel) { described_class.all_with_count_articles(unread: unread) }
        it { expect(rel.find { |r| r.id == subscription2.id }.count_articles(unread: unread)).to eq 0 }
      end
      context do
        let!(:unread) { false }
        let!(:rel) { described_class.all_with_count_articles(unread: unread) }
        it { expect(rel.find { |r| r.id == subscription2.id }.count_articles(unread: unread)).to eq 0 }
      end
    end

    describe 'count of articles of subscription#3' do
      context do
        let!(:unread) { true }
        let!(:rel) { described_class.all_with_count_articles(unread: unread) }
        it { expect(rel.find { |r| r.id == subscription3.id }.count_articles(unread: unread)).to eq 2 }
      end
      context do
        let!(:unread) { false }
        let!(:rel) { described_class.all_with_count_articles(unread: unread) }
        it { expect(rel.find { |r| r.id == subscription3.id }.count_articles(unread: unread)).to eq 2 }
      end
    end
  end
end
