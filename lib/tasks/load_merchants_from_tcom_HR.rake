MEANINGFUL_CHARS = "qwertzuiopasdfghjklyxcvbnm1234567890 ".split //

def expand_search(history = '')
  MEANINGFUL_CHARS.each { |c| yield ([history, c].join("")) }
end

def dont_fret
  begin
    yield
  rescue Exception => e
    @had_problem = true
    puts e.inspect unless e.is_a? NoMethodError
  end
end

def body_to_merchants(post)
  @counter = 0
  Merchant.transaction do
    doc = Hpricot (post.body)
    (doc/"html body div.mainLayoutwrapper div.contentwrapper div.contentInnerwrapper div#imenikContainer div#pretragaContainerInner_zuteStranice.pretragaContainerInner div.resultsPositioner div.ImenikContainerInnerDetails").each do |div_merchant|
      @had_problem = false
      m = Merchant.new
      dont_fret { m.name = (div_merchant/"div.ImenikContainerInnerDetailsLeft div.resultsTitle").inner_html }
      dont_fret { m.telephone_number = (div_merchant/"div.imenikSearchResultsRight div.imenikTelefon").inner_html }
      dont_fret { m.street = (div_merchant/"div.ImenikContainerInnerDetailsLeft ul.itemContactInfo li.secondColumn div").first.inner_html }
      dont_fret { m.city = (div_merchant/"div.ImenikContainerInnerDetailsLeft ul.itemContactInfo li.secondColumn div").last.inner_html }
      dont_fret { m.location_link = "http://imenik.tportal.hr/"+(div_merchant/"div.ImenikContainerInnerDetailsLeft ul.itemContactInfo li.firstColumn a.imenikNaKarti").first.attributes['href'] }
      m.additional_data = []
      (div_merchant/"div.ostaliPodaciContainer div.ostalipodaciText div.ostalipodaciTextInner div").each do |div_additional|
        dont_fret {
          k = (div_additional/"div.floatLeft span").inner_html.gsub('&nbsp;', '')
          v = (div_additional/"div.floatRight").inner_html
          m.additional_data << { k.strip => v.strip } unless k.blank? and v.blank?
        }
      end
      if not m.save
        printf ";"
      elsif @had_problem
        printf "!"
      else
        printf "."
      end
      @counter = @counter + 1
    end
  end
  return @counter
end

def ensure_tcp_success
  begin
    begin
      @repeat = false
      yield
    rescue Exception => e
      if e.is_a?(SocketError) or e.is_a?(Timeout::Error)
        @repeat = true
        puts " ensure_tcp_success #{e.inspect}"
        sleep 1
      else
        raise e
      end
    end
  end while @repeat
end

def import_search_results(http, query)
  printf query
  @page_count = 1
  @has_more = false

  @page = http.post('http://imenik.tportal.hr/show', "newSearch=1&action=pretraga&type=zuteStranice&kljucnerijeci=&naziv=#{query}&mjesto=&ulica=&zupanija=&pozivni=")
  @cookie_jar = @page.response['set-cookie'].split('; ',2)[0]
  while body_to_merchants(@page) == 100 and @page_count < 10
    printf " #{@page_count} \n  "
    @page_count = @page_count + 1
    @page = http.request( Net::HTTP::Get.new("http://imenik.tportal.hr/show?action=pretraga&type=zuteStranice&showResultsPage=#{@page_count}", {"Cookie" => @cookie_jar}) )
  end
  puts
  @has_more = true if @page_count == 10

  return @has_more
end

def perform_search(current)
  ensure_tcp_success do
    Net::HTTP.start('imenik.tportal.hr') do |http|
      @deepen_search = import_search_results http, current.search_string
      if @deepen_search
        SearchPath.transaction do
          expand_search (current.search_string) { |search_string| SearchPath.run(search_string, current.level + 1) }
        end
      end
    end
  end

  if @deepen_search
    current.incomplete!
  else
    current.complete!
  end
end

def run_search_on_level (level)
  SearchPath.where(:level => level, :status => "in progress").order("search_string").each do |search|
    perform_search(search)
  end
end

namespace :load_merchants do

  require 'net/http'
  require 'uri'
  require 'cgi'

  desc 'load merchant data from croatian t-com yellow pages'
  task :t_com_HR => :environment do
    @start_time = Time.now
    @counter = 0

    puts "Initializing search parameters"
    SearchPath.transaction do
      expand_search do |a|
        expand_search a do |search|
          SearchPath.run(search, 2)
        end
      end
    end

    puts "Starting import"    
    @level = 2
    while SearchPath.where(:status => 'in progress').count > 0
      puts "  =========================== RUNING LEVEL #{@level} ==============================="
      run_search_on_level @level
      @level = @level + 1
    end
    puts
    puts "SUCCESS!"
  end

end