class CreateFeedCaches < ActiveRecord::Migration[8.0]
  def change
    create_table :feed_caches do |t|
      t.references :channel, null: false, foreign_key: true
      t.text :contents
      t.datetime :cached_at

      t.timestamps
    end
  end
end
