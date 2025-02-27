class Subscription < ApplicationRecord
  has_many :articles, dependent: :delete_all
  has_one_attached :favicon

  validates :title, presence: true
  validates :src, presence: true

  def self.all_with_count_items(options = {})
    unread = options.fetch(:unread, false)
    as_name = options[:as_name].presence || 'count_items'

    additional_condition = unread ? 'AND articles.unread = true' : ''

    self
      .left_joins(:articles)
      .select("channels.*, COUNT(CASE WHEN articles.disabled = false #{additional_condition} THEN 1 END) AS #{sanitize_sql(as_name)}")
      .group('channels.id')
  end

  def count_articles(options = {})
    count_items(options)
  end

  def count_items(options = {})
    unread = options.fetch(:unread, false)
    as_name = options[:as_name].presence || 'count_items'

    rel = articles.where(disabled: false)
    if unread
      rel = rel.where(unread: true)
    end

    rel.length
  end

  def created?
    updated_at == created_at
  end
end
