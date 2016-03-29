json.array!(@sites) do |site|
  json.extract! site, :id, :name, :feed_url
  json.url_individual site_url(site)
end
