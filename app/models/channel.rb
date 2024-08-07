class Channel < ApplicationRecord
  def fetch
    RSS::Parser.parse(link)
  end
end
