SKIP_UNTIL = 'er'

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
      dont_fret {
        (div_merchant/"div.ostaliPodaciContainer div.ostalipodaciText div.ostalipodaciTextInner div").each do |div_additional|
          begin
            k = (div_additional/"div.floatLeft span").inner_html.gsub('&nbsp;', '')
            v = (div_additional/"div.floatRight").inner_html
            m.additional_data << { k.strip => v.strip } unless k.blank? and v.blank?
          rescue
          end
        end
      }
      if not m.save
        printf ";"
      elsif @had_problems
        printf "!"
      else
        printf "."
      end
      @counter = @counter + 1
    end
  end
  return @counter
end

namespace :load_merchants do

  require 'net/http'
  require 'uri'
  require 'cgi'

  desc 'load merchant data from croatian t-com yellow pages'
  task :t_com_HR => :environment do
    @start_time = Time.now
    @counter = 0
    @skip = true
    Net::HTTP.start('imenik.tportal.hr') do |http|
      @meaningful_chars = "qwertzuiopasdfghjklyxcvbnm1234567890".split //
      @meaningful_chars.each do |a|
        @meaningful_chars.each do |b|
          @current_search = [a,b].join ""
          @skip = false if @current_search == SKIP_UNTIL
          unless @skip
            printf @current_search
            @page_count = 1
            begin
              @page = http.post('http://imenik.tportal.hr/show', "newSearch=1&action=pretraga&type=zuteStranice&kljucnerijeci=&naziv=#{@current_search}&mjesto=&ulica=&zupanija=&pozivni=")
              @cookie_jar = @page.response['set-cookie'].split('; ',2)[0]
              while body_to_merchants(@page) == 100 and @page_count < 20
                printf " #{@page_count} \n  "
                @page_count = @page_count + 1
                @page = http.request( Net::HTTP::Get.new("http://imenik.tportal.hr/show?action=pretraga&type=zuteStranice&showResultsPage=#{@page_count}", {"Cookie" => @cookie_jar}) )
              end
              puts "PAGE COUNT IS 20!!" if @page_count == 20
              sleep 1
              puts
            rescue Exception => e
              puts e.inspect
            end
          end
        end
      end
    end
  end

end

=begin
require 'net/http'
require 'uri'
require 'cgi'
require 'open-uri'


Net::HTTP.start('imenik.tportal.hr') do |http|
  @current_search = 'la'
  post = http.post('http://imenik.tportal.hr/show', "newSearch=1&action=pretraga&type=zuteStranice&kljucnerijeci=&naziv=#{@current_search}&mjesto=&ulica=&zupanija=&pozivni=")
  puts post.body.length
  get = http.request( Net::HTTP::Get.new('http://imenik.tportal.hr/show?action=pretraga&type=zuteStranice&showResultsPage=2', {"Cookie" => post.response['set-cookie'].split('; ',2)[0]}) )
end


=end