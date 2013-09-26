class AddFieldsTo<%= table_name.camelize %> < ActiveRecord::Migration
  def self.up
    add_column :<%= table_name %>, :sash_id, :integer
    <%- resource = table_name.singularize -%>
  end

  def self.down
    remove_column :<%= table_name %>, :sash_id
  end
end
