require 'cinch'
require 'socket'

class JenkinsReceiver
  include Cinch::Plugin

  listen_to :monitor_msg, :method => :send_msg

  def send_msg(m, msg)
     Channel("#devops").send "Build notification: #{msg}"
  end

end

class BigBenBong
  include Cinch::Plugin

  match "big ben",{:use_prefix => false}

  def execute(m)
    reply = ''
    time = Time.now.hour
    if(time > 12) 
      time = time - 12
    end

    (1..time).each { |i| reply += "bong " }
    m.reply reply
    m.reply "It's #{time} a bong!"
  end
end


bot = Cinch::Bot.new do
  configure do |c|
    c.server = "192.168.59.103"
    c.nick = 'buzz'
    c.channels = ["#devops"]
    c.plugins.plugins = [JenkinsReceiver,BigBenBong]
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

end

def server(bot)
  print "Thread Start\n"
  server = TCPServer.new '127.0.0.1', 2000
  loop do
    Thread.start(server.accept) do |client|
      message = client.gets
      bot.handlers.dispatch(:monitor_msg, nil, message)
      client.puts "Ok\n"
      client.close
    end #Thread.Start
  end #loop
end

Thread.new { server(bot) }
bot.start