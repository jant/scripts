# skript vygeneruje ze zadaneho csv souboru a symbolu vice csv souboru pro vsechny obsazene kontraktni mesice
# a vygeneruje i seznam symbolu kontraktu oddeleny carkami
# priklad volani: ruby contract_data.rb c:/hd/hd.txt ZW

require "CSV"


def check_usage
  unless ARGV.length == 2
    puts "Usage: contract_data.rb csv_file symbol"
    exit
  end
end

MONTHS = {
    'F'=>'01',
    'G'=>'02',
    'H'=>'03',
    'J'=>'04',
    'K'=>'05',
    'M'=>'06',
    'N'=>'07',
    'Q'=>'08',
    'U'=>'09',
    'V'=>'10',
    'X'=>'11',
    'Z'=>'12'
}

def create_filename(contract)
  contract[0..1] + MONTHS[contract[2]] + contract[3..4] + '.Last.txt'
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
  if contract =~ Regexp.new(symbol) and contract.length == 5
    if !soubory.has_key?(contract)
      output = CSV.open(create_filename(contract), 'wb')
      soubory.store(contract, output) 
    else
      output = soubory[contract]
    end  
    output << [row[2], row[3], row[4], row[5], row[6], row[7]]
  end
end

File.open(File.join(output_dir_path, symbol + '_symbols.txt'), 'wb') do |file|
  soubory.each do |key, csv|
    file << key[0..1] + MONTHS[key[2]] + key[3..4] + ','
    csv.close
  end
end


