json.array!(@sites) do |site|
  json.extract! site, :id, :name, :feed_url, :channels
  json.url_individual site_url(site)
end
