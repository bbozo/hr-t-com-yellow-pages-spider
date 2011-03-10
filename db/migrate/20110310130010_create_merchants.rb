class CreateMerchants < ActiveRecord::Migration
  def self.up
    create_table :merchants do |t|
      t.string :name
      t.string :city
      t.string :street
      t.string :location_link
      t.string :telephone_number
      t.string :additional_data

      t.timestamps
    end
  end

  def self.down
    drop_table :merchants
  end
end
