module Factory
  # 指定した subscription の feed を取得し、含まれるエントリーすべてについて、
  # Article が存在しなければ作成します。存在すればそのエントリーについては何もしません。
  def fetch_and_merge_feed_entries_for_subscription(subscription)
    xml = FeedUtils.fetch(subscription.src)
    feed = FeedUtils.parse(xml)

    subscription.transaction do
      normalized_xml = normalize_feed_text(xml)
      FeedCache.where(subscription: subscription).each(&:destroy!)
      FeedCache.create(subscription: subscription, contents: normalized_xml, cached_at: Time.current)

      subscription.update(url: normalize_feed_text(feed.url))
      feed.entries.map {|entry| feed_entry_to_params_for_article(entry) }.each do |params|
        subscription.articles.create_with(params.merge(unread: true)).find_or_create_by!(guid: params[:guid])
      end
    end
  end

  # subscription の favicon を、その URL からダウンロードして更新します。
  # subscription の feed をいちどでも取得していなければ（キャッシュがなければ）何もしません。
  # feed から favicon の URL が特定できなければ、サイトの URL から favicon の URL を仮定して試みます。
  def fetch_favicon_and_update_for(subscription, async = false)
    cache = FeedCache.where(subscription: subscription).first&.contents
    feed = FeedUtils.parse(cache) if cache

    unless feed
      logger.info("ignore: requested favicon for subscription(#{subscription.id}), but that feed has never been retrieved yet")
      return
    end

    url = feed.respond_to?(:image) && feed.image && feed.image.url
    unless url
      unless feed.url
        logger.warn("requested favicon for subscription(#{subscription.id}), but that feed has no url (cache is broken?)")
        return
      end
      # try to download favicon.ico instead
      url = generate_default_favicon_url_from(feed.url)
    end

    if async
      DownloadSubscriptionFaviconJob.perform_later(subscription, url)
    else
      DownloadSubscriptionFaviconJob.perform_now(subscription, url)
    end
  end

  # entry をモデル Article のパラメータに変換します
  def feed_entry_to_params_for_article(entry)
    normalized_content = normalize_feed_text(entry.content)&.strip
    normalized_summary = normalize_feed_text(entry.summary)&.strip

    {
      guid: normalize_feed_text(entry.id),
      title: normalize_feed_text(entry.title)&.strip,
      url: normalize_feed_text(entry.url),
      description: normalized_content.presence || normalized_summary,
      pub_date: entry.published,
    }
  end

  def normalize_feed_text(value)
    return nil if value.nil?

    str = value.to_s
    return str if str.empty?

    utf8 = if str.encoding == Encoding::UTF_8
             str.valid_encoding? ? str : str.scrub
           else
             str.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '')
           end

    utf8.scrub
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
    str.b.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '').scrub
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
