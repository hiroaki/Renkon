require 'rails_helper'

RSpec.describe 'Subscriptions show', type: :request do
  describe 'GET /subscriptions/:id' do
    let!(:subscription) { FactoryBot.create(:subscription, src: 'https://example.com/feed.xml') }

    before do
      FactoryBot.create(:article, subscription: subscription, unread: true, disabled: false)
      FactoryBot.create(:article, subscription: subscription, unread: true, disabled: true)
      FactoryBot.create(:article, subscription: subscription, unread: false, disabled: false)
    end

    it 'renders the detail view without row-only unread badge markup' do
      get subscription_path(subscription)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Show subscription')
      expect(response.body).to include(subscription.src)
      expect(response.body).not_to include('data-unread-count=')
    end
  end
end
