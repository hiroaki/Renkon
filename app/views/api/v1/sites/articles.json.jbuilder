json.array!(@channel.articles) do |article|
  json.extract! article, :id, :channel_id, :title, :link, :pubdate, :guid
end
