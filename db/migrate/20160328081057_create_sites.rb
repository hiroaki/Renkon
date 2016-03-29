class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.string :name
      t.string :feed_url

      t.timestamps null: false
    end
  end
end
