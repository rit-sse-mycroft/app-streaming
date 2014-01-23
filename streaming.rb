require 'mycroft'

class Streaming < Mycroft::Client

  attr_accessor :verified

  def initialize(ui)
    @key = './streaming.key'
    @cert = './streaming.crt'
    @manifest = './app.json'
    @verified = false
    @players = {}
    @ui = ui
    super('localhost', nil)
  end

  def connect
    up
  end
  
  def sendUrl(url, dest = nil)
    query("video", "vido_stream", url, nil, dest)
  end

  def on_data(parsed)
    if parsed[:type] == 'MSG_QUERY_SUCCESS'
      puts "Stream started!"
    end
    if parsed[:type] == 'APP_DEPENDENCY'
      puts "Updating player list"
      @players = parsed[:data]['video']
      @players += parsed[:data]['speakers']
      @ui.players_changed(@players)
    end
  end

  def on_end
  end
end

