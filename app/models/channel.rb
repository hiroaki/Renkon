class Channel < ActiveRecord::Base
  belongs_to :site
  has_many :articles, dependent: :destroy
end
