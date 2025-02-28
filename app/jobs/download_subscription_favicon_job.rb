class DownloadSubscriptionFaviconJob < ApplicationJob
  queue_as :default

  def perform(*args)
    subscription = args[0]
    image_url = args[1]

    logger.info("The subscription (#{subscription.id}) has image: #{image_url}")

    response = HTTP.get(image_url)

    if response.status.success?
      filename = File.basename(URI.parse(image_url).path)

      subscription.favicon.attach(
        io: StringIO.new(response.body.to_s),
        filename: filename,
        content_type: response.content_type.to_s,
      )
      logger.info("Attached favicon to subscription [#{subscription.id}] [#{image_url}]")
    else
      logger.error("Failed to download for subscription [#{subscription.id}] [#{image_url}]: #{response.status}")
    end
  end
end
