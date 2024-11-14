class DownloadChannelFaviconJob < ApplicationJob
  queue_as :default

  def perform(*args)
    channel = args[0]
    image_url = args[1]

    logger.info("The channel (#{channel.id}) has image: #{image_url}")

    response = HTTP.get(image_url)

    if response.status.success?
      filename = File.basename(URI.parse(image_url).path)

      channel.favicon.attach(
        io: StringIO.new(response.body.to_s),
        filename: filename,
        content_type: response.content_type.to_s,
      )
      logger.info("Attached favicon to channel [#{channel.id}] [#{image_url}]")
    else
      logger.error("Failed to download for channel [#{channel.id}] [#{image_url}]: #{response.status}")
    end
  end
end
