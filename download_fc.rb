require 'mechanize'

unless ARGV.size == 2
	puts 'You need to run this script with two arguments: your firstclass username and your firstclass password'
	exit
end

# initialize new mechanize agent
agent = Mechanize.new
# get login page
page = agent.get('http://fc.chadwickschool.org/login/')
# fill out form using arguments passed to script
login_form = page.form('LOGINFORM')
login_form.userid   = ARGV[0]
login_form.password = ARGV[1]
# submit
puts "Logging in..."
page = agent.submit(login_form)
# go to inbox
page = page.link_with(text: 'Mailbox').click

puts "Downloading messages. This could take a while..."
File.open('firstclass_inbox.txt', 'w') do |f|
	loop do
		page.links_with(text: 'Message').each do |link|
			message_page = link.click

			# stuff holds the date and subject but not who sent it
			stuff = message_page.search('.p')
			# the format of the from address is completely fucked
			garbled_from = stuff[0].previous_sibling.content
			# but their name is enclosed by ` characters
			from_separator = "`"
			# so we'll extract it that way
			from = garbled_from[/#{from_separator}(.*?)#{from_separator}/m, 1]
			date = stuff[0].content
			subject = stuff[1].content
			message = message_page.search('div/*/tr')[1]

			f.puts 'SUBJECT: '+subject+"\n"
			f.puts 'FROM: '+from+"\n"
			f.puts 'DATE: '+date+"\n"
			f.puts message.content+"\n" unless message.nil?
			f.puts ('-'*100)+"\n"
		end
		break if !page.link_with(text: 'Next Page')
		page = page.link_with(text: 'Next Page').click
	end
end

puts "Saved inbox to firstclass_inbox.txt"