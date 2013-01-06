# skript vygeneruje ze zadaneho csv souboru a symbolu vice csv souboru pro vsechny obsazene kontraktni mesice


require "CSV"

def check_usage
  unless ARGV.length == 2
    puts "Usage: contract_data.rb csv_file symbol"
    exit
  end
end

check_usage

CSV.open('c:/HD/ZW/ZW 05-13.Last.txt', 'wb') do |output|
  CSV.foreach(ARGV[0]) do |row|
    if row[0] == 'ZWK13'
      output << [row[2], row[3], row[4], row[5], row[6], row[7]]
    end
  end
end


