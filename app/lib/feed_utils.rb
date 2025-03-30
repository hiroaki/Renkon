module FeedUtils
  module_function

  def get_feed_from(url)
    parse(fetch(url))
  end

  def fetch(url)
    res = HTTP.get(url)
    # TODO: check response
    res.body.to_s
  end

  def parse(xml)
    parser = Feedjira.parser_for_xml(xml)
    parser.preprocess_xml = true
    parser.parse(xml)
  end
end
