# skript vygeneruje ze zadaneho csv souboru a symbolu vice csv souboru pro vsechny obsazene kontraktni mesice
# priklad volani: ruby contract_data1.rb c:/hd/hd.csv ZW

require "CSV"


def check_usage
  unless ARGV.length == 2
    puts "Usage: contract_data.rb csv_file symbol"
    exit
  end
end

def filename(contract)
  contract + '.txt'
#  'ZW 05-13.Last.txt'
end

check_usage

input_file_path = ARGV[0]
symbol = ARGV[1]
input_dirname = File.dirname(input_file_path)
output_dir_path = File.join(input_dirname, symbol)
Dir.mkdir(output_dir_path) if !File.exists?(output_dir_path)
Dir.chdir(output_dir_path)

soubory = Hash.new

CSV.foreach(input_file_path) do |row|
  contract = row[0]
  if contract =~ Regexp.new(symbol)
    if !soubory.has_key?(contract)
      output = CSV.open(filename(contract), 'wb')
      soubory.store(contract, output) 
    else
      output = soubory[contract]
    end  
    output << [row[2], row[3], row[4], row[5], row[6], row[7]]
  end
end

soubory.each { |key, csv| csv.close}

