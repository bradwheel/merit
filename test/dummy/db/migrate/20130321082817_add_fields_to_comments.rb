class AddFieldsToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :sash_id, :integer
  end

  def self.down
    remove_column :comments, :sash_id
  end
end
