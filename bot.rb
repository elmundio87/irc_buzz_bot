require 'cinch'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "192.168.59.103"
    c.nick = 'buzz'
    c.channels = ["#devops"]
  end

  on :message, "hello" do |m|
    m.reply "Hello, #{m.user.nick}"
  end

  on :message, /^(.*)jenkins(.*)/ do |m, query|
    m.reply "I think you mean 'Jenkin'"
  end

  on :message, /\.\.\./ do |m, query|
    m.reply "haha"
  end

  on :message, /big ben/ do |m|
  	string = ''
  	time = Time.now.hour
  	if(time > 12) 
  		time = time - 12
  	end

  	(1..time).each { |i| string += "bong " }
  	m.reply string
  end  

end

bot.start