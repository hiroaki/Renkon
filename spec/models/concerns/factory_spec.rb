require 'rails_helper'

# NOTE: ほとんどのコードは Github Copilot の仕事です
RSpec.describe Factory, type: :module do
  let(:dummy_class) do
    Class.new do
      include Factory
      attr_accessor :logger
    end
  end
  let(:instance) { dummy_class.new }
  let(:subscription) { FactoryBot.create(:subscription) }
  let(:feed_utils) { class_double("FeedUtils").as_stubbed_const }
  let(:feed_cache) { class_double("FeedCache").as_stubbed_const }

  describe '#fetch_and_merge_feed_entries_for_subscription' do
    let(:xml) { "<rss></rss>" }
    let(:feed) { double("Feed", url: "http://example.com", entries: [entry]) }
    let(:entry) { double("Entry", id: "123", title: "Title", url: "http://example.com/article", content: "Content", summary: "Summary", published: Time.now) }

    before do
      allow(feed_utils).to receive(:fetch).with(subscription.src).and_return(xml)
      allow(feed_utils).to receive(:parse).with(xml).and_return(feed)
      allow(feed_cache).to receive(:where).with(subscription: subscription).and_return([double("FeedCache", destroy!: true)])
      allow(feed_cache).to receive(:create).with(subscription: subscription, contents: xml, cached_at: anything)
      allow(subscription).to receive(:update).with(url: feed.url)
      allow(subscription.articles).to receive(:create_with).and_return(subscription.articles)
      allow(subscription.articles).to receive(:find_or_create_by!).with(guid: entry.id)
    end

    it 'fetches and merges feed entries for subscription' do
      expect { instance.fetch_and_merge_feed_entries_for_subscription(subscription) }.not_to raise_error
    end
  end

  describe '#fetch_favicon_and_update_for' do
    let(:cache) { double("FeedCache", contents: "<rss></rss>") }
    let(:feed) { double("Feed", url: "http://example.com", image: double("Image", url: "http://example.com/favicon.ico")) }

    before do
      allow(feed_utils).to receive(:parse).and_return(feed)
      allow(DownloadSubscriptionFaviconJob).to receive(:perform_now)
      allow(DownloadSubscriptionFaviconJob).to receive(:perform_later)
    end

    context 'when cache is present' do
      before do
        allow(feed_cache).to receive(:where).with(subscription: subscription).and_return([cache])
      end

      context 'when async is false' do
        it 'fetches and updates favicon synchronously' do
          expect(DownloadSubscriptionFaviconJob).to receive(:perform_now).with(subscription, feed.image.url)
          instance.fetch_favicon_and_update_for(subscription, false)
        end
      end

      context 'when async is true' do
        it 'fetches and updates favicon asynchronously' do
          expect(DownloadSubscriptionFaviconJob).to receive(:perform_later).with(subscription, feed.image.url)
          instance.fetch_favicon_and_update_for(subscription, true)
        end
      end
    end

    context 'when cache is nil' do
      before do
        allow(feed_cache).to receive(:where).with(subscription: subscription).and_return([])
      end

      it 'does not perform any updates and logs a message' do
        expect(instance).to receive(:logger).and_return(double(info: true, warn: true))
        instance.fetch_favicon_and_update_for(subscription, false)
      end
    end

    context 'when feed.url is nil' do
      let(:cache) { double("FeedCache", contents: "<rss></rss>") }
      let(:feed) { double("Feed", url: nil, image: double("Image", url: nil)) }
      let(:logger) { double("Logger", info: true, warn: true) }

      before do
        allow(instance).to receive(:logger).and_return(logger)
        allow(feed_cache).to receive(:where).with(subscription: subscription).and_return([cache])
        allow(feed_utils).to receive(:parse).and_return(feed)
      end

      it 'logs a warning message' do
        expect(logger).to receive(:warn).with("requested favicon for subscription(#{subscription.id}), but that feed has no url (cache is broken?)")
        instance.fetch_favicon_and_update_for(subscription, false)
      end
    end

context 'when feed.image.url is nil and feed.url is present' do
  let(:cache) { double("FeedCache", contents: "<rss></rss>") }
  let(:feed) { double("Feed", url: "http://example.com", image: double("Image", url: nil)) }
  let(:generated_url) { "http://example.com/favicon.ico" }

  before do
    allow(feed_cache).to receive(:where).with(subscription: subscription).and_return([cache])
    allow(feed_utils).to receive(:parse).and_return(feed)
    allow(instance).to receive(:generate_default_favicon_url_from).with(feed.url).and_return(generated_url)
    allow(DownloadSubscriptionFaviconJob).to receive(:perform_now)
  end

  it 'generates default favicon URL and fetches the favicon synchronously' do
    expect(DownloadSubscriptionFaviconJob).to receive(:perform_now).with(subscription, generated_url)
    instance.fetch_favicon_and_update_for(subscription, false)
  end

  it 'generates default favicon URL and fetches the favicon asynchronously' do
    expect(DownloadSubscriptionFaviconJob).to receive(:perform_later).with(subscription, generated_url)
    instance.fetch_favicon_and_update_for(subscription, true)
  end
end
  end

  describe '#feed_entry_to_params_for_article' do
    context 'when all fields are present' do
      let(:entry) { double("Entry", id: "123", title: "Title", url: "http://example.com/article", content: "Content", summary: "Summary", published: Time.now) }
      it 'converts feed entry to article params' do
        params = instance.feed_entry_to_params_for_article(entry)
        expect(params).to eq({
          guid: entry.id,
          title: entry.title.strip,
          url: entry.url,
          description: entry.content.strip,
          pub_date: entry.published
        })
      end
    end

    context 'when title, content, and summary are nil' do
      let(:entry) { double("Entry", id: "123", title: nil, url: "http://example.com/article", content: nil, summary: nil, published: Time.now) }
      it 'converts feed entry to article params with nil title, content, and summary' do
        params = instance.feed_entry_to_params_for_article(entry)
        expect(params).to eq({
          guid: entry.id,
          title: nil,
          url: entry.url,
          description: nil,
          pub_date: entry.published
        })
      end
    end
  end


  describe '#generate_default_favicon_url_from' do
    shared_examples 'generates default favicon URL' do |url, expected_favicon_url|
      it "generates default favicon URL for #{url}" do
        favicon_url = instance.generate_default_favicon_url_from(url)
        expect(favicon_url).to eq(expected_favicon_url)
      end
    end

    include_examples 'generates default favicon URL', 'http://example.com', 'http://example.com/favicon.ico'
    include_examples 'generates default favicon URL', 'https://example.com', 'https://example.com/favicon.ico'
    include_examples 'generates default favicon URL', 'http://example.com:8080', 'http://example.com:8080/favicon.ico'
    include_examples 'generates default favicon URL', 'https://example.com:8443', 'https://example.com:8443/favicon.ico'
    include_examples 'generates default favicon URL', 'http://example.com:8080/path/to/resource', 'http://example.com:8080/favicon.ico'
    include_examples 'generates default favicon URL', 'https://example.com:8443/path/to/resource', 'https://example.com:8443/favicon.ico'
  end
end
