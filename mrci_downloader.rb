require 'rubygems'
require 'mechanize'

#http://www.ruby-forum.com/topic/216780 


def check_usage
  unless ARGV.length == 2
    puts "Usage: ruby c:\t\scripts\mrci_downloader.rb password_to_mrci_account c:\temp"
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
page = agent.page.link_with(:href => '/web/mrci-online.html').click
page = agent.page.link_with(:text => 'Special Spread Charts').click

links = agent.page.links_with(:href => /specialspreadchartsdownload/)

output_dir = File.join(ARGV[1],Time.now.strftime("%Y-%m-%d"))
Dir.mkdir(output_dir)
Dir.chdir(output_dir)

links.each do |link|
  begin
    link.click.save 
    print '.'  
  rescue
    begin
      link.click.save 
    rescue
      puts
      puts 'ERROR ' + link.text
    end 
  end
end



