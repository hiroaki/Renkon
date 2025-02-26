module Factory
  # 指定した channel の feed を取得し、含まれるエントリーすべてについて、
  # Item が存在しなければ作成します。存在すればそのエントリーについては何もしません。
  def fetch_and_merge_feed_entries_for_channel(channel)
    xml = FeedUtils.fetch(channel.src)
    feed = FeedUtils.parse(xml)

    channel.transaction do
      FeedCache.where(channel: channel).each(&:destroy!)
      FeedCache.create(channel: channel, contents: xml, cached_at: Time.current)

      channel.update(url: feed.url)
      feed.entries.map {|entry| feed_entry_to_params_for_item(entry) }.each do |params|
        channel.items.create_with(params.merge(unread: true)).find_or_create_by!(guid: params[:guid])
      end
    end
  end

  # channel の favicon を、その URL からダウンロードして更新します。
  # channel の feed をいちどでも取得していなければ（キャッシュがなければ）何もしません。
  # feed から favicon の URL が特定できなければ、サイトの URL から favicon の URL を仮定して試みます。
  def fetch_favicon_and_update_for(channel, async = false)
    cache = FeedCache.where(channel: channel).first&.contents
    feed = FeedUtils.parse(cache) if cache

    unless feed
      logger.info("ignore: requested favicon for channel(#{channel.id}), but that feed has never been retrieved yet")
      return
    end

    url = feed.respond_to?(:image) && feed.image && feed.image.url
    unless url
      unless feed.url
        logger.warn("requested favicon for channel(#{channel.id}), but that feed has no url (cache is broken?)")
        return
      end
      # try to download favicon.ico instead
      url = generate_default_favicon_url_from(feed.url)
    end

    if async
      DownloadChannelFaviconJob.perform_later(channel, url)
    else
      DownloadChannelFaviconJob.perform_now(channel, url)
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

  # 与えられた url から、そのサイトの favicon.ico があるであろう URL を生成します。
  def generate_default_favicon_url_from(url)
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
