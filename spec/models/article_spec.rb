require 'rails_helper'

# NOTE: "Copilot" とコメントしているブロックは、 GitHub Copilot が出力したテスト
RSpec.describe Article, type: :model do
  describe '基本' do
    let!(:article) { FactoryBot.build(:article) }
    it '既定の Factory が valid であり、レコードが保存できる' do
      expect { article.save! }.not_to raise_error
    end
  end

  # Copilot
  describe 'associations' do
    it { should belong_to(:subscription) }
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

  # Copilot
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:url) }
  end

  # Copilot
  describe 'scopes' do
    let!(:enabled_article) { FactoryBot.create(:article, disabled: false) }
    let!(:disabled_article) { FactoryBot.create(:article, disabled: true) }

    describe '.enabled' do
      it 'returns enabled articles' do
        expect(Article.enabled).to include(enabled_article)
        expect(Article.enabled).not_to include(disabled_article)
      end
    end

    describe '.disabled' do
      it 'returns disabled articles' do
        expect(Article.disabled).to include(disabled_article)
        expect(Article.disabled).not_to include(enabled_article)
      end
    end

    describe '.in_trash' do
      it 'returns articles in trash' do
        expect(Article.in_trash).to include(disabled_article)
        expect(Article.in_trash).not_to include(enabled_article)
      end
    end
  end

  describe '.empty_trash' do
    let!(:article_in_trash) { FactoryBot.create(:article, disabled: true) }
    let!(:article_not_in_trash) { FactoryBot.create(:article, disabled: false) }

    it 'deletes all articles in trash' do
      expect { Article.empty_trash }.to change { Article.in_trash.count }.by(-1)
    end

    it 'does not delete articles not in trash' do
      Article.empty_trash
      expect(Article.exists?(article_not_in_trash.id)).to be true
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
