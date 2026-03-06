class Group < ApplicationRecord
  belongs_to :parent, class_name: 'Group', optional: true
  has_many :children, class_name: 'Group', foreign_key: :parent_id, dependent: :nullify
  has_many :subscriptions, dependent: :nullify

  validates :name, presence: true

  scope :ordered, -> { order(position: :asc, id: :asc) }

  before_validation :assign_position, on: :create

  private

    def assign_position
      return if position.present?

      siblings = Group.where(parent_id: parent_id)
      self.position = (siblings.maximum(:position) || 0) + 1
    end
end
