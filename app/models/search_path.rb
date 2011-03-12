class SearchPath < ActiveRecord::Base

  validates_uniqueness_of :search_string
  validates :status, :presence => true
  validates :level, :presence => true

  def self.run(search_string, level)
    puts "   * initiating search on #{search_string}, level #{level}"
    old_search = SearchPath.find_by_search_string(search_string)
    if old_search
      return old_search
    else
      return create!(:search_string => search_string, :status => "in progress", :level => level) if not old_search
    end
  end

  def complete!
    update_attribute :status, 'complete'
  end

  def complete?
    status == 'complete'
=begin
    return true if status == 'complete'

    (2..search_string.length).each do |len|
      (0..search_string.length-len).each do |offs|
        #puts "#{search_string[offs...offs+len]} => #{SearchPath.where(:search_string => search_string[offs...offs+len], :status => 'complete').count} - #{SearchPath.where(:search_string => search_string[offs...offs+len], :status => 'complete').to_sql}"
        return true if SearchPath.where(:search_string => search_string[offs...offs+len], :status => 'complete').count > 0
      end
    end

    return false
=end
  end

  def in_progress?
    status == 'in progress'
  end

  def self.perform(search_string, level)
    search = SearchPath.run(search_string, level)
    yield unless search.complete?
    search.complete!
  end

end
