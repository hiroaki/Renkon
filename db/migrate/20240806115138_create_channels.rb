class CreateChannels < ActiveRecord::Migration[7.1]
  def change
    create_table :channels do |t|
      t.string :title
      t.string :link
      t.text :description
      t.datetime :last_build_date

      t.timestamps
    end
  end
end
