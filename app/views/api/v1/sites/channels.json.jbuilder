json.array!(@sites) do |site|
  json.extract! site, :id, :name, :feed_url
  json.url_individual site_url(site)
  json.channels site.channels do |channel|
    json.extract! channel, :id, :site_id, :title, :date, :description, :link
    json.url_articles api_v1_channels_articles_url(channel)
  end
end
