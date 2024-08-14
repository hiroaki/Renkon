module FeedUtils
  module_function

  def fetch(url)
    res = HTTP.get(url)
    # TODO: check response
    xml = res.body.to_s

    parser = Feedjira.parser_for_xml(xml)
    parser.preprocess_xml = true
    parser.parse(xml)
  end
end
