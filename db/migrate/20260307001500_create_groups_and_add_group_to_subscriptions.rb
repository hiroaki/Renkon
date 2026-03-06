class CreateGroupsAndAddGroupToSubscriptions < ActiveRecord::Migration[8.0]
  class MigrationGroup < ApplicationRecord
    self.table_name = 'groups'
  end

  class MigrationSubscription < ApplicationRecord
    self.table_name = 'subscriptions'
  end

  def up
    create_table :groups do |t|
      t.string :name, null: false
      t.references :parent, foreign_key: { to_table: :groups }, null: true
      t.integer :position, null: false

      t.timestamps
    end

    add_index :groups, [:parent_id, :position]

    add_reference :subscriptions, :group, foreign_key: true, null: true

    say_with_time 'Creating default root group and assigning subscriptions' do
      root = MigrationGroup.create!(name: 'Default', parent_id: nil, position: 1)
      MigrationSubscription.update_all(group_id: root.id)
    end
  end

  def down
    remove_reference :subscriptions, :group, foreign_key: true
    drop_table :groups
  end
end
