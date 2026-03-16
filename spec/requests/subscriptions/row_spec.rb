require 'rails_helper'

RSpec.describe 'Subscriptions row', type: :request do
  describe 'GET /subscriptions/:id/row' do
    let!(:subscription) { FactoryBot.create(:subscription, src: 'https://example.com/feed.xml') }

    before do
      FactoryBot.create(:article, subscription: subscription, unread: true, disabled: false)
      FactoryBot.create(:article, subscription: subscription, unread: true, disabled: true)
      FactoryBot.create(:article, subscription: subscription, unread: false, disabled: false)
    end

    it 'renders the compact row response with unread aggregate count' do
      get row_subscription_path(subscription)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("data-unread-count=\"1\"")
      expect(response.body).to include(%(turbo-frame id="subscription_#{subscription.id}"))
    end
  end
end