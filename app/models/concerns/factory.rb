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

    if feed.image.url
      logger.info("The channel (#{channel.id}) has image: #{feed.image.url}")
      # FeedImageUpdateJob.perform_lator(channel.id, feed.image.url)

      response = HTTP.get(feed.image.url)

      if response.status.success?
        filename = File.basename(URI.parse(feed.image.url).path)

        channel.favicon.attach(
          io: StringIO.new(response.body.to_s),
          filename: filename,
          content_type: response.content_type.to_s,
        )
      else
        logger.error("(Ignore) Failed to download [#{feed.image.url}]: #{response.status}")
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
end
