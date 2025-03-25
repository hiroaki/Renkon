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
  end

  describe '.parse' do
    it 'parses the XML feed' do
      parsed_feed = FeedUtils.parse(xml)
      expect(parsed_feed).to be_a(Feedjira::Parser::RSS)
      expect(parsed_feed.title).to eq('Sample Feed')
    end
  end
end
