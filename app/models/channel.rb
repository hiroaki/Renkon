class Channel < ApplicationRecord
  has_many :items, dependent: :delete_all

  validates :title, presence: true
  validates :src, presence: true

  def self.all_with_count_items(options = {})
    unread = options[:unread].presence
    as_name = options[:as_name].presence || 'items_count'

    rel = all.left_outer_joins(:items).group('channels.id').select("channels.*, COUNT(`items`.`id`) AS #{as_name}")
    unless unread.nil?
      # LEFT OUTER JOIN した結果、 Channel の items が 0 件の時、
      # WHERE 句に items.unread を指定するとマッチするものがなく、
      # その Channel が除外されてしまいます（結合結果を WHERE しているため）
      # unread IS NULL OR unread ... とすることで除外を免れます。
      # 別解として JOIN の ON の条件に unread の条件を追加することが考えられます。
      rel = rel.where(items: { unread: [nil, unread] })
    end
    rel
  end
end
