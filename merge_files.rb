# skript slouci do jednoho souboru obsah vsech souboru v zadanem adresari
# z kazdeho souboru vynecha prvni radek
# vysledny soubor zalozi v zadanem adresari


def check_usage
  unless ARGV.length == 2
    puts "Usage: merge_files.rb dir_path merge_filename"
    exit
  end
end

check_usage
Dir.chdir(ARGV[0])
File.open ARGV[1], 'w' do |mergedfile|
  Dir['*'].each do |f|
    File.readlines(f).each_with_index do |line, i|
      mergedfile << line if i > 0
    end
  end
end


