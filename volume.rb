require 'rubygems'
require 'nokogiri'
require 'watir'

# nelze pouzit pouze nokogiri ba ani mechanize, protoze obsah HTML je generovany javasriptem, takze musime pouzit simulaci browseru

browser = Watir::Browser.new

browser.minimize

browser.goto "http://www.cmegroup.com/trading/agricultural/livestock/live-cattle_quotes_volume_voi.html"

until browser.table(:id=>"futuresMonth").exists? do sleep 1 end

page = Nokogiri::HTML(browser.html)

browser.close

nodes = page.xpath("//table[@id='futuresMonth']/tbody/tr")

nodes.each do |node|
  cells = node.xpath('td')
  if cells.length > 0 
    puts cells[0].text + '  ' + cells[1].text
  end
end

#//*[@id="futuresMonth"]/tbody/tr[4]/td[1]