module FeedUtils
  module_function

  def fetch(url)
    res = HTTP.get(url)
    # TODO: check response
    xml = res.body.to_s
    Feedjira.parse(xml)
  end
end
