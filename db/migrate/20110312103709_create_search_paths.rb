class CreateSearchPaths < ActiveRecord::Migration
  def self.up
    create_table :search_paths do |t|
      t.string :search_string
      t.string :status
      t.integer :level

      t.timestamps
    end

    add_index :search_paths, [:search_string]
  end

  def self.down
    drop_table :search_paths
  end
end
