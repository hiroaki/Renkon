class Subscription < ApplicationRecord
  has_many :articles, dependent: :delete_all
  has_one_attached :favicon

  validates :title, presence: true
  validates :src, presence: true

  def self.all_with_count_articles(options = {})
    unread = options.fetch(:unread, false)
    as_name = options[:as_name].presence || 'count_articles'

    additional_condition = unread ? 'AND articles.unread = true' : ''

    self
      .left_joins(:articles)
      .select("subscriptions.*, COUNT(CASE WHEN articles.disabled = false #{additional_condition} THEN 1 END) AS #{sanitize_sql(as_name)}")
      .group('subscriptions.id')
  end

  def count_articles(options = {})
    count_articles(options)
  end

  def count_articles(options = {})
    unread = options.fetch(:unread, false)
    as_name = options[:as_name].presence || 'count_articles'

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
