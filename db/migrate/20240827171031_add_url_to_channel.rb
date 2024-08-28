class AddUrlToChannel < ActiveRecord::Migration[7.1]
  def up
    add_column :channels, :url, :string, null: true
    rename_column :channels, :link, :src
  end

  def down
    remove_column :channels, :url
    rename_column :channels, :src, :link
  end
end
