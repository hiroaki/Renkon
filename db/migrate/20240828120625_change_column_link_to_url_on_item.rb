class ChangeColumnLinkToUrlOnItem < ActiveRecord::Migration[7.1]
  def up
    rename_column :items, :link, :url
  end

  def down
    rename_column :items, :url, :link
  end
end
