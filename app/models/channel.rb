class Channel < ApplicationRecord
  has_many :items, dependent: :delete_all

  def self.all_with_count_items(unread = nil, as_name = 'items_count')
    rel = all.left_joins(:items).group(:id).select("channels.*, COUNT(`items`.`id`) AS #{as_name}")
    unless unread.nil?
      rel = rel.where(items: { unread: unread })
    end
    rel
  end
end
