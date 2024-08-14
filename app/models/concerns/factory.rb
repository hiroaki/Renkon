module Factory
  # 指定した channel の feed を取得し、含まれるエントリーすべてについて、
  # Item が存在しなければ作成します。存在すればそのエントリーについては何もしません。
  def fetch_and_merge_feed_entries_for_channel(channel)
    feed = FeedUtils.fetch(channel.link)

    channel.transaction do
      feed.entries.map {|entry| feed_entry_to_params_for_item(entry) }.each do |params|
        channel.items.create_with(params.merge(unread: true)).find_or_create_by!(guid: params[:guid])
      end
    end
  end

  # entry をモデル Item のパラメータに変換します
  def feed_entry_to_params_for_item(entry)
    {
      guid: entry.id,
      title: entry.title&.strip,
      link: entry.url,
      description: entry.content&.strip || entry.summary&.strip,
      pub_date: entry.published,
    }
  end
end
