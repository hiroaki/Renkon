require 'rails_helper'
require 'feedjira'
require 'http'
require 'webmock/rspec'

RSpec.describe FeedUtils do
  let(:url) { 'http://example.com/feed.xml' }
  let(:xml) do
    <<-XML
      <rss version="2.0">
        <channel>
          <title>Sample Feed</title>
          <link>http://example.com/</link>
          <description>This is a sample RSS feed</description>
          <item>
            <title>Sample Item</title>
            <link>http://example.com/sample-item</link>
            <description>This is a sample item</description>
          </item>
        </channel>
      </rss>
    XML
  end

  before do
    stub_request(:get, url).to_return(body: xml, status: 200)
  end

  describe '.get_feed_from' do
    it 'fetches the feed from the URL and parses it' do
      parsed_feed = FeedUtils.get_feed_from(url)
      expect(parsed_feed).to be_a(Feedjira::Parser::RSS)
      expect(parsed_feed.title).to eq('Sample Feed')
    end
  end

  describe '.fetch' do
    it 'fetches the feed from the URL' do
      result = FeedUtils.fetch(url)
      expect(result).to eq(xml)
    end

    it 'raises HttpError when the upstream response is not successful' do
      stub_request(:get, url).to_return(status: 503, body: 'unavailable')

      expect { FeedUtils.fetch(url) }
        .to raise_error(FeedUtils::HttpError, 'Feed source is temporarily unavailable (HTTP 503). Try again later.')
    end

    it 'raises InvalidFeedError when the response body is empty' do
      stub_request(:get, url).to_return(status: 200, body: '')

      expect { FeedUtils.fetch(url) }
        .to raise_error(FeedUtils::InvalidFeedError, 'Feed source returned an empty response. Check the subscription URL or settings.')
    end
  end

  describe '.parse' do
    it 'parses the XML feed' do
      parsed_feed = FeedUtils.parse(xml)
      expect(parsed_feed).to be_a(Feedjira::Parser::RSS)
      expect(parsed_feed.title).to eq('Sample Feed')
    end

    it 'raises InvalidFeedError when the payload is not a feed' do
      expect { FeedUtils.parse('<html><body>not a feed</body></html>') }
        .to raise_error(FeedUtils::InvalidFeedError, 'Source did not return a valid RSS or Atom feed. Check the subscription URL or settings.')
    end
  end
end
