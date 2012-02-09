# skript vygeneruje soubor, ktery slouzi jako slovnik pro vim dictionary completion (Ctrl-x, Ctrl-k)
# do slovniku zahrne vsechny soubory z daneho adresare, ktere maji danou priponu, typicky *.am
# slovnik pouzivam pro rychle vkladani hypertext. odkazu ve vimwiki (kazdy odkaz je reprezentovan souborem s priponou 'am')


def check_usage
  unless ARGV.length == 2
    puts "Usage: gen_vimwiki_dict.rb wiki_folder dict_filename"
    exit
  end
end

check_usage
entries = Dir.entries(ARGV[0]).select {|s| s =~ /.am$/}
File.open(ARGV[0] + '/' + ARGV[1], 'w') {|f| f.write entries.join("\n")}

