class Site < ActiveRecord::Base
  has_many :channels, dependent: :destroy
  validates :name, presence: true
  validates :feed_url, presence: true

  def reload!
    rss = Renkon::RSS::Agent.fetch_feed!(feed_url)

    channel = Channel.create_with(
      site_id: id,
      title: rss.channel.title,
      date: rss.channel.date,
      description: rss.channel.description
    ).find_or_create_by(link: rss.channel.link)

    rss.items.each do |item|
      guid = item.try(:guid).try(:content)
      guid = item.link unless guid
      unless guid
        raise "cannot detect the guid of an item on channel=[#{channel.id}]"
      end

      article = Article.find_by(channel_id: channel.id, guid: guid)
      if article
        if article.same_as_item?(item)
          logger.debug("article=[#{article.id}] on channel=[#{channel.id}] exists, skip")
          next
        end
        logger.debug("article=[#{article.id}] on channel=[#{channel.id}] exists but modified, to update")
      else
        logger.debug("new article guid=[#{guid}]")
        article = Article.new(channel_id: channel.id, guid: guid)
      end

      article.update(
        title: item.title,
        link: item.link,
        description: item.description,
        author: item.author,
        pubdate: item.pubDate,
        permalink: item.guid.try(:PermaLink?),
        content: item.content_encoded
      )
    end
    self
  end
end
