class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.integer :channel_id, null: false
      t.string :title
      t.string :link
      t.text :description
      t.string :author
      t.timestamp :pubdate
      t.boolean :permalink
      t.text :guid
      t.text :content

      t.timestamps null: false
    end
  end
end
