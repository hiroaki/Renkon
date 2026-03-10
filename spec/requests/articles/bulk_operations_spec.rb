require 'rails_helper'

RSpec.describe 'Article bulk operations', type: :request do
  describe 'PATCH /subscriptions/:subscription_id/articles/bulk_update_read_status' do
    it 'updates unread flag for valid ids in the subscription' do
      subscription = FactoryBot.create(:subscription)
      article1 = FactoryBot.create(:article, subscription: subscription, unread: true, disabled: false)
      article2 = FactoryBot.create(:article, subscription: subscription, unread: true, disabled: false)

      patch bulk_update_read_status_subscription_articles_path(subscription),
        params: {
          article_ids: [article1.id, article2.id],
          target_unread: false,
        },
        as: :json

      expect(response).to have_http_status(:ok)
      body = json_body
      expect(body['succeeded_ids']).to contain_exactly(article1.id, article2.id)
      expect(body['failed_ids']).to eq([])

      expect(article1.reload.unread).to be(false)
      expect(article2.reload.unread).to be(false)
    end

    it 'returns failure ids for records outside the subscription' do
      subscription = FactoryBot.create(:subscription)
      other_subscription = FactoryBot.create(:subscription)
      article = FactoryBot.create(:article, subscription: subscription, unread: true, disabled: false)
      external = FactoryBot.create(:article, subscription: other_subscription, unread: true, disabled: false)

      patch bulk_update_read_status_subscription_articles_path(subscription),
        params: {
          article_ids: [article.id, external.id],
          target_unread: false,
        },
        as: :json

      expect(response).to have_http_status(:ok)
      body = json_body
      expect(body['succeeded_ids']).to eq([article.id])
      expect(body['failed_ids']).to eq([external.id])
      expect(body['errors'][external.id.to_s]).to eq('article not found in the subscription')

      expect(article.reload.unread).to be(false)
      expect(external.reload.unread).to be(true)
    end

    it 'returns 422 when article_ids is invalid' do
      subscription = FactoryBot.create(:subscription)

      patch bulk_update_read_status_subscription_articles_path(subscription),
        params: {
          article_ids: ['oops'],
          target_unread: false,
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body['error']).to eq('article_ids contains invalid id')
    end
  end

  describe 'PATCH /subscriptions/:subscription_id/articles/bulk_delete' do
    it 'disables enabled articles and destroys disabled articles' do
      subscription = FactoryBot.create(:subscription)
      enabled = FactoryBot.create(:article, subscription: subscription, unread: true, disabled: false)
      disabled = FactoryBot.create(:article, subscription: subscription, unread: true, disabled: true)

      patch bulk_delete_subscription_articles_path(subscription),
        params: {
          article_ids: [enabled.id, disabled.id],
        },
        as: :json

      expect(response).to have_http_status(:ok)
      body = json_body
      expect(body['succeeded_ids']).to contain_exactly(enabled.id, disabled.id)
      expect(body['disabled_ids']).to eq([enabled.id])
      expect(body['destroyed_ids']).to eq([disabled.id])
      expect(body['failed_ids']).to eq([])

      expect(enabled.reload.disabled).to be(true)
      expect(Article.exists?(disabled.id)).to be(false)
    end

    it 'returns failed ids for records outside the subscription' do
      subscription = FactoryBot.create(:subscription)
      other_subscription = FactoryBot.create(:subscription)
      article = FactoryBot.create(:article, subscription: subscription, unread: true, disabled: false)
      external = FactoryBot.create(:article, subscription: other_subscription, unread: true, disabled: false)

      patch bulk_delete_subscription_articles_path(subscription),
        params: {
          article_ids: [article.id, external.id],
        },
        as: :json

      expect(response).to have_http_status(:ok)
      body = json_body
      expect(body['succeeded_ids']).to eq([article.id])
      expect(body['failed_ids']).to eq([external.id])
      expect(body['errors'][external.id.to_s]).to eq('article not found in the subscription')

      expect(article.reload.disabled).to be(true)
      expect(external.reload.disabled).to be(false)
    end

    it 'returns 422 when article_ids is empty' do
      subscription = FactoryBot.create(:subscription)

      patch bulk_delete_subscription_articles_path(subscription),
        params: {
          article_ids: [],
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body['error']).to eq('article_ids must not be empty')
    end
  end
end
