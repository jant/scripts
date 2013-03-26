require 'rubygems'
require 'mechanize'

#http://www.ruby-forum.com/topic/216780 


def check_usage
  unless ARGV.length == 2
    puts "Usage: mrci_dovnloader.rb password_to_mrci_account output_dir"
    exit
  end
end

check_usage

agent = Mechanize.new
agent.pluggable_parser.default = Mechanize::Download

page = agent.get('http://www.mrci.com/web/index.php')

form = page.form('form-login')

form.username = 'tjanousek@volny.cz'
form.passwd = ARGV[0]

page = agent.submit(form, form.buttons.first)

page = agent.page.link_with(:text => 'MRCI Online').click
page = agent.page.link_with(:text => 'Special Spread Charts').click

#page = agent.page.link_with(:href => '/specialspreadchartsdownload-135.htm').click
#page.save

links = agent.page.links_with(:href => /specialspreadchartsdownload/)

output_dir = File.join(ARGV[1],Time.now.strftime("%Y-%m-%d"))
Dir.mkdir(output_dir)
Dir.chdir(output_dir)

links.each do |link|
  link.click.save 
  print '.'  
end



