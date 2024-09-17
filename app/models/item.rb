class Item < ApplicationRecord
  belongs_to :channel

  validates :title, presence: true
  validates :url, presence: true

  scope :enabled, -> { where(disabled: false) }
  scope :disabled, -> { where(disabled: true) }

  def unread?
    unread == true
  end
end
