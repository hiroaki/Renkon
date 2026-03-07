class Group < ApplicationRecord
  ROOT_NAME = 'Subscriptions'.freeze

  belongs_to :parent, class_name: 'Group', optional: true
  has_many :children, class_name: 'Group', foreign_key: :parent_id, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(position: :asc, id: :asc) }

  before_validation :assign_position, on: :create

  def self.default_root!
    ordered.find_by(parent_id: nil) || create!(name: ROOT_NAME, parent_id: nil)
  end

  private

    def assign_position
      return if position.present?

      siblings = Group.where(parent_id: parent_id)
      self.position = (siblings.maximum(:position) || 0) + 1
    end
end
