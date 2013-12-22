require 'rubygems'
require 'nokogiri'
require 'watir'

# nelze pouzit pouze nokogiri ba ani mechanize, protoze obsah HTML je generovany javascriptem, takze musime pouzit simulaci browseru

TABLE = {

'LE'=> 'live-cattle',  
'HE'=> 'lean-hogs',
'GF'=> 'feeder-cattle',
'ZC'=> 'corn',
'ZW'=> 'wheat',
'ZM'=> 'soybean-meal',
'ZL'=> 'soybean-oil'
}


def check_usage
  unless ARGV.length == 1
    puts "Usage: ruby volume.rb contract_symbol"
    exit
  end
end

check_usage


symbol = ARGV[0]

if not TABLE.has_key? symbol
  puts 'Neznamy symbol ' + symbol
  puts 'Pouzij: '
  puts TABLE
  exit
end

browser = Watir::Browser.new

browser.minimize

if ['LE','HE', 'GF'].include?(symbol)
  folder = 'livestock'
else
  folder = 'grain-and-oilseed'
end

browser.goto "http://www.cmegroup.com/trading/agricultural/#{folder}/#{TABLE[symbol]}_quotes_volume_voi.html"

until browser.table(:id=>"futuresMonth").exists? do sleep 1 end

page = Nokogiri::HTML(browser.html)

browser.close

nodes = page.xpath("//table[@id='futuresMonth']/tbody/tr")

puts '-------------------------------'
puts TABLE[ARGV[0]] + ' (' + ARGV[0] + ')' 
puts '-------------------------------'

nodes.each do |node|
  cells = node.xpath('td')
  if cells.length > 0 and cells[0].text != 'TOTALS'
    puts cells[0].text + '  ' + cells[1].text
  end
end


