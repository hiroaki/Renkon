module FeedUtils
  class Error < StandardError
    attr_reader :retryable

    def initialize(message, retryable:)
      super(message)
      @retryable = retryable
    end

    def retryable?
      @retryable
    end
  end

  class FetchError < Error
    def initialize(message = 'Could not reach the feed source. Try again later.')
      super(message, retryable: true)
    end
  end

  class HttpError < Error
    attr_reader :status_code

    def initialize(status_code)
      @status_code = status_code.to_i

      super(self.class.message_for(@status_code), retryable: self.class.retryable_status?(@status_code))
    end

    def self.retryable_status?(status_code)
      status_code == 408 || status_code == 429 || status_code >= 500
    end

    def self.message_for(status_code)
      if retryable_status?(status_code)
        "Feed source is temporarily unavailable (HTTP #{status_code}). Try again later."
      else
        "Feed source returned HTTP #{status_code}. Check the subscription URL or settings."
      end
    end
  end

  class InvalidFeedError < Error
    def initialize(message = 'Source did not return a valid RSS or Atom feed. Check the subscription URL or settings.')
      super(message, retryable: false)
    end
  end

  module_function

  def get_feed_from(url)
    parse(fetch(url))
  end

  def fetch(url)
    res = HTTP.get(url)
    raise HttpError.new(res.status.to_i) unless res.status.success?

    body = res.body.to_s
    raise InvalidFeedError.new('Feed source returned an empty response. Check the subscription URL or settings.') if body.blank?

    body
  rescue URI::InvalidURIError
    raise InvalidFeedError.new('Feed URL is invalid. Check the subscription settings.')
  rescue HTTP::Error, IOError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
    raise FetchError
  end

  def parse(xml)
    parser = Feedjira.parser_for_xml(xml)
    raise InvalidFeedError unless parser

    parser.preprocess_xml = true
    parser.parse(xml)
  rescue FeedUtils::Error
    raise
  rescue StandardError
    raise InvalidFeedError.new('Feed content could not be parsed as RSS or Atom. Check the subscription URL or settings.')
  end
end
