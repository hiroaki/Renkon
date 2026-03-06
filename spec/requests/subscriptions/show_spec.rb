require 'rails_helper'

RSpec.describe 'Subscriptions show', type: :request do
  describe 'GET /subscriptions/:id' do
    let!(:subscription) { FactoryBot.create(:subscription, src: 'https://example.com/feed.xml') }

    before do
      FactoryBot.create(:article, subscription: subscription, unread: true, disabled: false)
      FactoryBot.create(:article, subscription: subscription, unread: true, disabled: true)
      FactoryBot.create(:article, subscription: subscription, unread: false, disabled: false)
    end

    it 'renders short response with unread aggregate count' do
      get subscription_path(subscription), params: { short: true }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("data-unread-count=\"1\"")
    end
  end
end
