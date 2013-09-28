require 'rubygems'
require 'mechanize'

agent = Mechanize.new
page = agent.get('http://www.cmegroup.com/trading/agricultural/grain-and-oilseed/corn_quotes_volume_voi.html')

page.search('Corn').each do |cell|
  puts cell.content
end