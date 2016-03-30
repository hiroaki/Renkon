class Article < ActiveRecord::Base
  belongs_to :channel

  def same_as_item?(rss_item)
    [[:pubdate, :pubDate], [:title, :title], [:link, :link], [:content, :content_encoded]].all? do |keys|
      send(keys[0]) == rss_item.send(keys[1])
    end
  end
end
