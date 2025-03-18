require 'rails_helper'

# NOTE: "Copilot" とコメントしているブロックは、 GitHub Copilot が出力したテスト
RSpec.describe Subscription, type: :model do
  describe '基本' do
    let!(:subscription) { FactoryBot.build(:subscription) }
    it '既定の Factory が valid であり、レコードが保存できる' do
      expect { subscription.save! }.not_to raise_error
    end

    it 'has many articles with dependent delete all' do
      expect(subject).to have_many(:articles).dependent(:delete_all)
    end
  end

  # Copilot
  describe 'associations' do
    it { should have_many(:articles).dependent(:delete_all) }
    it { should have_one_attached(:favicon) }
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

  # Copilot
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:src) }
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

  # Copilot
  describe '.all_with_count_articles' do
    let!(:subscription_with_articles) { FactoryBot.create(:subscription) }
    let!(:subscription_without_articles) { FactoryBot.create(:subscription) }
    let!(:article) { FactoryBot.create(:article, subscription: subscription_with_articles, disabled: false) }
    let!(:unread_article) { FactoryBot.create(:article, subscription: subscription_with_articles, unread: true, disabled: false) }

    context 'when unread is false' do
      it 'returns subscriptions with article counts' do
        result = Subscription.all_with_count_articles(unread: false)
        subscription = result.find { |s| s.id == subscription_with_articles.id }
        expect(subscription.attributes['count_articles'].to_i).to eq(2)
      end
    end

    context 'when unread is true' do
      it 'returns subscriptions with unread article counts' do
        result = Subscription.all_with_count_articles(unread: true)
        subscription = result.find { |s| s.id == subscription_with_articles.id }
        expect(subscription.attributes['count_articles'].to_i).to eq(1)
      end
    end
  end

  # Copilot
  describe '#count_articles' do
    let(:subscription) { FactoryBot.create(:subscription) }
    let!(:article1) { FactoryBot.create(:article, subscription: subscription, disabled: false) }
    let!(:article2) { FactoryBot.create(:article, subscription: subscription, disabled: false, unread: true) }

    context 'when unread is false' do
      it 'returns the count of enabled articles' do
        expect(subscription.count_articles(unread: false)).to eq(2)
      end
    end

    context 'when unread is true' do
      it 'returns the count of unread and enabled articles' do
        expect(subscription.count_articles(unread: true)).to eq(1)
      end
    end
  end

  # Copilot
  describe '#created?' do
    let(:subscription) { FactoryBot.create(:subscription) }

    context 'when created_at equals updated_at' do
      it 'returns true' do
        expect(subscription.created?).to be true
      end
    end

    context 'when created_at does not equal updated_at' do
      before do
        subscription.update(title: 'Updated Title')
      end

      it 'returns false' do
        expect(subscription.created?).to be false
      end
    end
  end
end
