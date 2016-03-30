require 'rss'

file = ARGV[0]
if file.nil?
  puts "Usage: ./bin/rails runner script/rss.rb feed_url|xml"
  exit
end

# RSS::RDF when it parsed RSS 1.0, or
# RSS::Rss when RSS 0.9x/2.0
rss = Renkon::RSS::Agent.fetch_feed!(file)

channel = rss.channel

puts "#{rss.class}"
puts "  encoding: #{rss.encoding}"
puts "  rss_version: #{rss.rss_version}"
puts
puts "#{channel.class}"
puts "  title: #{channel.title}"
puts "  date: #{channel.date}"
puts "  description: #{channel.description}"
puts "  link: #{channel.link}"
puts
puts "#{rss.items.size} items:"
rss.items.each do |item|
  puts "- #{item.class}"
  puts "  title: #{item.title}"
  puts "  link: #{item.link}"
  puts "  description.size = #{item.description.size}"
  puts "  author: #{item.author}"
  puts "  pubDate: #{item.pubDate}"
  if item.guid
    puts "  permalink: #{item.guid.PermaLink?}"
    puts "  content.size: #{item.guid.content}"
  else
    puts "  *** guid is not presented"
  end
  if item.content_encoded
    puts "  content_encoded.size = #{item.content_encoded.size}"
  else
    puts "  *** content_encoded is not presented"
  end
  puts
end
