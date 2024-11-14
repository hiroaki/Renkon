module Factory
  # 指定した channel の feed を取得し、含まれるエントリーすべてについて、
  # Item が存在しなければ作成します。存在すればそのエントリーについては何もしません。
  def fetch_and_merge_feed_entries_for_channel(channel)
    feed = FeedUtils.fetch(channel.src)

    channel.transaction do
      channel.update(url: feed.url)
      feed.entries.map {|entry| feed_entry_to_params_for_item(entry) }.each do |params|
        channel.items.create_with(params.merge(unread: true)).find_or_create_by!(guid: params[:guid])
      end
    end

    unless channel.favicon.attached?
      if feed.respond_to?(:image) && feed.image && feed.image.url
        DownloadChannelFaviconJob.perform_later(channel, feed.image.url)
      else
        # try to download favicon.ico instead
        DownloadChannelFaviconJob.perform_later(channel, generate_favicon_url_from(feed.url))
      end
    end
  end

  # entry をモデル Item のパラメータに変換します
  def feed_entry_to_params_for_item(entry)
    {
      guid: entry.id,
      title: entry.title&.strip,
      url: entry.url,
      description: entry.content&.strip || entry.summary&.strip,
      pub_date: entry.published,
    }
  end

  def generate_favicon_url_from(url)
    uri = URI.parse(url)
    host = uri.host
    port = uri.port
    base_url = if (uri.scheme == 'http' && port != 80) || (uri.scheme == 'https' && port != 443)
                 "#{uri.scheme}://#{host}:#{port}"
               else
                 "#{uri.scheme}://#{host}"
               end

    "#{base_url}/favicon.ico"
  end
end
