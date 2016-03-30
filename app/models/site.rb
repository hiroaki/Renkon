class Site < ActiveRecord::Base
  has_many :channels, dependent: :destroy
  validates :name, presence: true
  validates :feed_url, presence: true
end
