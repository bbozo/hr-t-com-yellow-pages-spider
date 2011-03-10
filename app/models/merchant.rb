class Merchant < ActiveRecord::Base

  serialize :additional_data

  validate do |m|
    m.errors.add_to_base("duplicate entry - #{m.attributes.inspect}") if m.duplicates.count > 0
  end

  def duplicates
    Merchant.where(self.attributes.except("id", "updated_at", "created_at", "additional_data"))
  end

end
