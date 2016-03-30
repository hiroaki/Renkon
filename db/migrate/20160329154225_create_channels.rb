class CreateChannels < ActiveRecord::Migration
  def change
    create_table :channels do |t|
      t.integer :site_id, null: false
      t.string :title, null: false
      t.timestamp :date
      t.string :description, null: false
      t.string :link, null: false

      t.timestamps null: false
    end
  end
end
