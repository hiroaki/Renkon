class AddChannelRefToItem < ActiveRecord::Migration[7.1]
  def change
    add_reference :items, :channel, null: false, foreign_key: true
  end
end
