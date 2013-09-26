class AddFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :sash_id, :integer
  end

  def self.down
    remove_column :users, :sash_id
  end
end
