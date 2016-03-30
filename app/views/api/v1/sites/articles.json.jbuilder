json.array!(@channel.articles) do |article|
  json.set! :site, article.channel.site
  json.set! :channel, article.channel
  json.extract! article, :id, :channel_id, :title, :link, :pubdate, :guid, :description, :content
end
