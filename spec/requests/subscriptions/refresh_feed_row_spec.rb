require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'Subscriptions refresh_feed_row', type: :request do
  describe 'PATCH /subscriptions/:id/refresh_feed_row' do
    let!(:subscription) { FactoryBot.create(:subscription, src: source_url) }
    let(:source_url) { 'http://example.com/feed.xml' }

    it 'returns permanent error details when the source is not a valid feed' do
      stub_request(:get, source_url).to_return(status: 200, body: '<html><body>not a feed</body></html>')

      patch refresh_feed_row_subscription_path(subscription)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body['category']).to eq('permanent')
      expect(json_body['error']).to include('valid RSS or Atom feed')
    end

    it 'returns temporary error details when the upstream source is unavailable' do
      stub_request(:get, source_url).to_return(status: 503, body: 'unavailable')

      patch refresh_feed_row_subscription_path(subscription)

      expect(response).to have_http_status(:service_unavailable)
      expect(json_body['category']).to eq('temporary')
      expect(json_body['error']).to include('Try again later')
    end

    it 'fetches feed and redirects to the compact row on success' do
      stub_request(:get, source_url).to_return(
        status: 200,
        body: <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <rss version="2.0">
            <channel>
              <title>Feed</title>
              <link>https://example.com/feed</link>
              <description>ok</description>
            </channel>
          </rss>
        XML
      )

      patch refresh_feed_row_subscription_path(subscription)

      expect(response).to have_http_status(:see_other)
      expect(response.headers['Location']).to end_with(row_subscription_path(subscription))
      expect(a_request(:get, source_url)).to have_been_made.once
    end
  end
end