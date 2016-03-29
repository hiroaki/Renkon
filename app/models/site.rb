class Site < ActiveRecord::Base
  validates :name, presence: true
  validates :feed_url, presence: true
end
