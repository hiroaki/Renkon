class Item < ApplicationRecord
  belongs_to :channel

  scope :enabled, -> { where(disabled: false) }
  scope :disabled, -> { where(disabled: true) }

  def unread?
    unread == true
  end
end
