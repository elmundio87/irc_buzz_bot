require 'cinch'
require 'socket'
require 'redis'
require 'json'

class JenkinsReceiver
  include Cinch::Plugin

  listen_to :monitor_msg, :method => :send_msg

  def send_msg(m, msg)
    a = JSON.parse msg
    Channel("#devops").send "Build notification: #{a['name']} #{a['build']['phase']} - #{a['build']['status']}"
  end

end

class TrelloBot
  include Cinch::Plugin

  require 'trello'

  match /trello i am (.*)/, :method => :login, :use_prefix => false 
  match /trello api (.*)/, :method => :api, :use_prefix => false 
  match /trello whoami/, :method => :whoami, :use_prefix => false 
  match /trello what am I doing?/, :method => :whatamidoing, :use_prefix => false 

  def getBoard(id)

    redis = Redis.new(:url => "redis://redis:6379/1")
    board = redis.get("trello_board_#{id}")

    if(board == nil)
      board = Trello::Board.find(id).name
      redis.set("trello_board_#{id}",board)
    end
      
    board

  end

  def getList(id)
    redis = Redis.new(:url => "redis://redis:6379/1")
    list = redis.get("trello_list_#{id}")
    
    if(list == nil)
      list = Trello::List.find(id).name
      redis.set("trello_list_#{id}",list)
    end
    
    list
    
  end

  def login(m,text)
    redis = Redis.new(:url => "redis://redis:6379/1")
    redis.set("trello_nick_#{m.user.nick}",text)
    m.reply "#{m.user.nick} is #{text}"
    m.reply "Go to https://trello.com/1/authorize?key=7d2dda2064b808df2348e238b1e8b72f&name=Buzz&expiration=30days&response_type=token&scope=read,write"
    m.reply "and type 'trello api <your api key>'"
  end

  def api(m,text)
    redis = Redis.new(:url => "redis://redis:6379/1")
    redis.set("trello_api_#{m.user.nick}",text)
    m.reply "Api key has been cached"
  end

  def whoami(m)
    redis = Redis.new(:url => "redis://redis:6379/1")
    name = redis.get("trello_nick_#{m.user.nick}")
    if(name != nil)
      m.reply "#{m.user.nick}'s name in Trello is #{name}"
    else
      m.reply "I don't recognise you. Login using 'trello login <Your Name>'"
    end
  end

  def whatamidoing(m)
    redis = Redis.new(:url => "redis://redis:6379/1")
    user = redis.get("trello_nick_#{m.user.nick}")
    
    m.reply "Looking..."
    
    if(redis.get("trello_api_#{m.user.nick}") == nil)
      m.reply "I don't recognise you. Login using 'trello login <your trello username>'"
      return
    end

    Trello.configure do |config|
      config.developer_public_key = '7d2dda2064b808df2348e238b1e8b72f'
      config.member_token = redis.get("trello_api_#{m.user.nick}")
    end

  begin
    cards = Trello::Member.find(user).cards
  rescue
    m.reply "ERROR: User '#{user}' was not found. Are you sure that's correct?"
    return
  end

    reply = []

    cards.each do |card|
      list = getList(card.attributes[:list_id])
      if(list == "In Progress" || list == "Doing")
        reply << card.attributes[:name] + " : " + card.attributes[:url]
      end
    end

    m.reply reply.join("\n")
    m.reply "Done! (#{reply.length} results found)"

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
    c.server = "ircd"
    c.nick = 'buzz'
    c.channels = ["#devops"]
    c.plugins.plugins = [JenkinsReceiver,BigBenBong,TrelloBot]
  end

  on :message, "hello" do |m|
    m.reply "Hello, #{m.user.nick}"
  end

  on :message, /^(.*)(?i:jenkins)(.*)/ do |m, query|
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
