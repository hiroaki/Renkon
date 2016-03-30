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
      if !item.guid.content
        logger.warn "item.guid is not presented"
      else
        Article.find_or_initialize_by(guid: item.guid.content).update(
          channel_id: channel.id,
          title: item.title,
          link: item.link,
          description: item.description,
          author: item.author,
          pubdate: item.pubDate,
          permalink: item.guid.PermaLink?,
          content: item.content_encoded
          )
      end
    end
  end
end
