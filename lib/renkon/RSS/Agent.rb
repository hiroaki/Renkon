require 'rss'

module Renkon
  module RSS
    module Agent
      module_function
      def fetch_feed!(url_or_file)
        if File.exist?(url_or_file)
          xml = File.open(url_or_file).read
        elsif /^https?:/ =~ url_or_file #/
          xml = url_or_file
        else
          raise ArgumentError
        end
        ::RSS::Parser.parse(xml)
      end
    end
  end
end
