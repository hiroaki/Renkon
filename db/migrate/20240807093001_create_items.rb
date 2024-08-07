class CreateItems < ActiveRecord::Migration[7.1]
  def change
    create_table :items do |t|
      t.string :title
      t.string :link
      t.text :description
      t.datetime :pub_date
      t.string :guid
      t.boolean :unread

      t.timestamps
    end
  end
end
