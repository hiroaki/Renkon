json.array!(@channel.articles.order(pubdate: :desc)) do |article|
  json.set! :site, article.channel.site
  json.set! :channel, article.channel
  json.extract! article, :id, :channel_id, :title, :link, :pubdate, :guid, :description, :content
end
