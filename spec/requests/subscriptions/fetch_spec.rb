require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'Subscriptions fetch', type: :request do
  describe 'PATCH /subscriptions/:id/fetch' do
    let!(:subscription) { FactoryBot.create(:subscription, src: source_url) }
    let(:source_url) { 'http://example.com/feed.xml' }

    it 'returns permanent error details when the source is not a valid feed' do
      stub_request(:get, source_url).to_return(status: 200, body: '<html><body>not a feed</body></html>')

      patch fetch_subscription_path(subscription), params: { short: true }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body['category']).to eq('permanent')
      expect(json_body['error']).to include('valid RSS or Atom feed')
    end

    it 'returns temporary error details when the upstream source is unavailable' do
      stub_request(:get, source_url).to_return(status: 503, body: 'unavailable')

      patch fetch_subscription_path(subscription), params: { short: true }

      expect(response).to have_http_status(:service_unavailable)
      expect(json_body['category']).to eq('temporary')
      expect(json_body['error']).to include('Try again later')
    end
  end
end
