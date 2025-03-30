class Article < ApplicationRecord
  belongs_to :subscription

  validates :title, presence: true
  validates :url, presence: true

  scope :enabled, -> { where(disabled: false) }
  scope :disabled, -> { where(disabled: true) }
  scope :in_trash, -> { where(disabled: true) }

  def self.empty_trash
    self.in_trash.delete_all
  end

  def unread?
    unread == true
  end
end
