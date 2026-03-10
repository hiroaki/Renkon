require 'rails_helper'

RSpec.describe 'Article show request', type: :request do
  describe 'GET /subscriptions/:subscription_id/articles/:id' do
    it 'returns 404 for missing article on normal html request' do
      subscription = FactoryBot.create(:subscription)

      get subscription_article_path(subscription, 999_999)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 204 for turbo frame request when article is missing' do
      subscription = FactoryBot.create(:subscription)

      get subscription_article_path(subscription, 999_999), headers: {
        'Turbo-Frame' => 'contents',
      }

      expect(response).to have_http_status(:no_content)
    end
  end
end
