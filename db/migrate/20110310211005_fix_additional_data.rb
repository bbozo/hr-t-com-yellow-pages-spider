class FixAdditionalData < ActiveRecord::Migration
  def self.up
    remove_column :merchants, :additional_data
    add_column :merchants, :additional_data, :text
  end

  def self.down
    remove_column :merchants, :additional_data
    add_column :merchants, :additional_data, :string
  end
end
