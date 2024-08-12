class AddDisabledToItem < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :disabled, :boolean, null: false, default: false
  end
end
