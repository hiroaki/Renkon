class ChangeModelsName < ActiveRecord::Migration[8.0]
  def up
    rename_table :channels, :subscriptions
    rename_table :items, :articles

    rename_column :articles, :channel_id, :subscription_id
    rename_column :feed_caches, :channel_id, :subscription_id
  end

  def down
    rename_column :feed_caches, :subscription_id, :channel_id
    rename_column :articles, :subscription_id, :channel_id

    rename_table :articles, :items
    rename_table :subscriptions, :channels
  end
end
