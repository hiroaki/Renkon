class AddPositionToSubscriptions < ActiveRecord::Migration[8.0]
  class MigrationSubscription < ApplicationRecord
    self.table_name = 'subscriptions'
  end

  def up
    add_column :subscriptions, :position, :integer

    say_with_time 'Backfilling subscriptions.position' do
      position = 0
      MigrationSubscription.unscoped.order(created_at: :asc, id: :asc).find_each do |subscription|
        position += 1
        subscription.update_columns(position: position)
      end
    end

    change_column_null :subscriptions, :position, false
    add_index :subscriptions, :position
  end

  def down
    remove_index :subscriptions, :position
    remove_column :subscriptions, :position
  end
end
