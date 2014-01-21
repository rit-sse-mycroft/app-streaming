require 'mycroft'

class Streaming < Mycroft::Client

  attr_accessor :verified

  def initialize
    @key = './streaming.key'
    @cert = './streaming.crt'
    @manifest = './app.json'
    @verified = false
    @host = 'localhost'
    @players = {}
    super
  end
  
  def reg_ui(ui)
    @ui = ui
  end

  def connect
    up
  end
  
  def sendUrl(url, dest = nil)
    query("video", "stream", url, nil, dest)
  end

  def on_data(parsed)
    if parsed[:type] == 'MSG_QUERY_SUCCESS'
      puts "Stream started!"
    end
    if parsed[:type] == 'APP_DEPENDENCY'
      puts "Updating player list"
      @players = parsed[:data]['video']
      @ui.players_changed(@players)
    end
  end

  def on_end
  end
end

