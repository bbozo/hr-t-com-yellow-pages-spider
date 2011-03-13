class SearchPath < ActiveRecord::Base

  validates_uniqueness_of :search_string
  validates :status, :presence => true
  validates :level, :presence => true

  def self.clean_up_by_supersets(level)
    puts "Cleaning supersets for level #{level}"
    SearchPath.where(:level => level, :status => "in progress").order("search_string").each do |search|
      superset_search = SearchPath.find_superset(search.search_string, level)
      if superset_search
        puts "   * skipping search path on '#{search.search_string}', level #{level}, already complete within '#{superset_search.search_string}'"
        search.complete!
      end
    end
    puts "  DONE!"
  end

  def self.run(search_string, level)   
    old_search = SearchPath.find_by_search_string(search_string)
    superset_search = SearchPath.find_superset(search_string, level) unless old_search

    if old_search
      puts "   * confirming search path on '#{search_string}', level #{level}, status is #{old_search.status}"
      return old_search
    elsif superset_search
      puts "   * skipping search path on '#{search_string}', level #{level}, already complete within '#{superset_search.search_string}'"
      return create!(:search_string => search_string, :status => "complete", :level => level)
    else
      puts "   * initiating search path on '#{search_string}', level #{level}"
      return create!(:search_string => search_string, :status => "in progress", :level => level) if not old_search
    end
  end

  def self.find_superset(search_string, level)
    (1..search_string.length-(level-1)).each do |offs|
      #puts "#{search_string[offs...offs+(level-1)]} => #{SearchPath.where(:search_string => search_string[offs...offs+(level-1)], :status => 'complete').count} - #{SearchPath.where(:search_string => search_string[offs...offs+(level-1)], :status => 'complete').to_sql}"
      superset = SearchPath.where(:search_string => search_string[offs...offs+(level-1)], :status => 'complete').first
      return superset if superset
    end
      
    return nil
  end

  def complete!
    update_attribute :status, 'complete'
  end

  def incomplete!
    update_attribute :status, 'incomplete'
  end

  def finished?
    not in_progress?
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

  def incomplete?
    status == 'incomplete'
  end

  def in_progress?
    status == 'in progress'
  end

end
