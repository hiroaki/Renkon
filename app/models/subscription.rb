class Subscription < ApplicationRecord
  belongs_to :group, optional: true

  has_many :articles, dependent: :delete_all
  has_many :feed_caches, dependent: :delete_all
  has_one_attached :favicon

  before_validation :assign_position, on: :create

  validates :title, presence: true
  validates :src, presence: true

  scope :ordered, -> { order(group_id: :asc, position: :asc, id: :asc) }
  scope :ordered_within_group, ->(group_id) { where(group_id: group_id).order(position: :asc, id: :asc) }

  def self.all_with_count_articles(options = {})
    unread = options.fetch(:unread, false)
    as_name = options[:as_name].presence || 'count_articles'

    additional_condition = unread ? 'AND articles.unread = true' : ''

    self
      .left_joins(:articles)
      .select("subscriptions.*, COUNT(CASE WHEN articles.disabled = false #{additional_condition} THEN 1 END) AS #{sanitize_sql(as_name)}")
      .group('subscriptions.id')
      .ordered
  end

  def count_articles(options = {})
    unread = options.fetch(:unread, false)

    rel = articles.where(disabled: false)

    if unread
      rel = rel.where(unread: true)
    end

    rel.count
  end

  def created?
    updated_at == created_at
  end

  private

    def assign_position
      return if position.present?

      siblings = Subscription.where(group_id: group_id)
      self.position = (siblings.maximum(:position) || 0) + 1
    end
end
