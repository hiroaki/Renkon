class Channel < ApplicationRecord
  has_many :items

  def fetch
    RSS::Parser.parse(link)
  end
end
